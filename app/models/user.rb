require 'securerandom'
require 'devise'
require 'digest'

class User < ApplicationRecord
  include MentionsUsers
  include UserIndexing

  serialize :announcements_seen, type: Array, coder: YAML

  scope :moderators, -> { joins(:roles).where(roles: { name: 'moderator' }) }
  scope :administrators, -> { joins(:roles).where(roles: { name: 'administrator' }) }
  scope :script_authors, -> { where(stats_script_count: 1..) }

  scope :banned, -> { where.not(banned_at: nil) }
  scope :not_banned, -> { where(banned_at: nil) }

  has_many :authors, dependent: :destroy
  has_many :scripts, through: :authors
  has_many :reports_as_reporter, foreign_key: :reporter_id, inverse_of: :reporter, class_name: 'Report', dependent: nil
  has_many :discussions, foreign_key: 'poster_id', inverse_of: :poster, dependent: nil
  has_many :comments, foreign_key: 'poster_id', inverse_of: :poster, dependent: nil
  has_many :discussion_subscriptions, dependent: :destroy
  has_many :mentions_as_target, class_name: 'Mention', dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :user_notification_settings, dependent: :destroy

  # Gotta to it this way because you can't pass a parameter to a has_many, and we need it has_many
  # to do eager loading.
  Script.subsets.each do |subset|
    has_many :"#{subset}_listable_scripts", -> { listable(subset) }, class_name: 'Script', through: :authors, source: :script
  end

  has_and_belongs_to_many :roles, dependent: :destroy

  has_many :identities, dependent: :destroy

  has_many :script_sets, dependent: :destroy

  belongs_to :locale, optional: true

  has_and_belongs_to_many :conversations
  has_many :conversation_subscriptions, dependent: :destroy

  generates_token_for(:one_click_unsubscribe)

  before_destroy(prepend: true) do
    scripts.select { |script| script.authors.where.not(user_id: id).none? }.each do |script|
      if banned?
        # Retain the evidence
        script.update_columns(locked: true, delete_type: 'keep', delete_reason: 'User deleted', deleted_at: Time.zone.now)
      else
        script.destroy!
      end
    end
  end

  BANNED_EMAIL_SALT = '95b68f92d7f373b07dfe101a4b3b46708ae161739b263016eefa3d01762879936507ff2a55442e9a47c681d895de4d905565e2645caff432a987b07457bc005b'.freeze

  after_destroy do
    next unless canonical_email && banned_at

    hash = Digest::SHA1.hexdigest(BANNED_EMAIL_SALT + canonical_email)
    BannedEmailHash.create(email_hash: hash, deleted_at: Time.current, banned_at:) unless BannedEmailHash.where(email_hash: hash).any?
  end

  def self.email_previously_banned_and_deleted?(email)
    return false unless email

    email = EmailAddress.canonical(email)
    hash = Digest::SHA1.hexdigest(BANNED_EMAIL_SALT + email)
    BannedEmailHash.where(email_hash: hash).any?
  end

  def self.allow_registrations_for_email!(email)
    email = EmailAddress.canonical(email)
    hash = Digest::SHA1.hexdigest(BANNED_EMAIL_SALT + email)
    beh = BannedEmailHash.find_by(email_hash: hash)
    return false unless beh

    beh.destroy!
    true
  end

  before_validation do
    self.canonical_email = EmailAddress.canonical(email)
  end

  before_save do
    self.email_domain = email&.split('@')&.last
    self.registration_email_domain ||= email_domain
  end

  after_create_commit do
    job = UserCheckingJob
    job = job.set(wait: 1.minute) if Rails.env.production?
    job.perform_later(self)
  end

  after_update do
    # To clear partial caches
    scripts.touch_all if saved_change_to_name?
  end

  after_update_commit if: ->(model) { model.previous_changes.key?('name') } do
    scripts.indexable.reindex(mode: :async) if Searchkick.callbacks?
  end

  before_update do
    # Recheck it if it's disposable the next time we need to know.
    self.disposable_email = nil if email_changed? && !disposable_email_changed?
  end

  # Include default devise modules. Others available are:
  # :lockable and :omniauthable
  devise :two_factor_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable, :confirmable, :timeoutable

  # Prevent session termination vulnerability
  # https://makandracards.com/makandra/53562-devise-invalidating-all-sessions-for-a-user
  def authenticatable_salt
    "#{super}#{session_token}"
  end

  def invalidate_all_sessions!
    self.session_token = SecureRandom.hex
  end

  validates :name, :profile_markup, :preferred_markup, presence: true
  # Cn is reserved unicode characters
  validates :name, uniqueness: { case_sensitive: false }, length: { minimum: 1, maximum: 50 }, format: { without: /\p{Cn}/ }
  validates :profile, length: { maximum: 10_000 }
  validates :profile_markup, inclusion: { in: %w[html markdown] }
  validates :preferred_markup, inclusion: { in: %w[html markdown] }
  validates :locale, presence: { message: :invalid }, if: -> { locale_id.present? }

  validate do
    errors.add(:email) if new_record? && identities.none? && !EmailAddress.valid?(email)
  end

  validate do
    next unless new_record? && email

    errors.add(:email) if SpammyEmailDomain.find_for_email(email)&.block_type_register?
  end

  validate do
    errors.add(:base, 'This email has been banned.') if (new_record? || email_changed? || unconfirmed_email_changed?) && (User.banned.where(canonical_email:).any? || User.email_previously_banned_and_deleted?(canonical_email))
  end

  validate do
    next unless (new_record? || name_changed?) && name

    invisible_char_regex = /\p{Cf}/
    errors.add(:name, :uniqueness) if name.match?(invisible_char_regex) && User.where.not(id:).where(name: name.gsub(invisible_char_regex, '')).any?
  end

  # Devise runs this when password_required?, and we override that so
  # that users don't have to deal with passwords all the time. Add it
  # back when Devise won't run it and the user is actually setting the
  # password.
  validates :password, confirmation: { if: proc { |u| !u.password_required? && !u.password.nil? } }

  strip_attributes

  def discussions_on_scripts_written
    Discussion.not_deleted.where(script: script_ids).order(stat_last_reply_date: :desc)
  end

  def to_param
    slug = slugify(name)
    return id.to_s if slug.blank?

    "#{id}-#{slug}"
  end

  def moderator?
    self.class.moderator_ids.include?(id)
  end

  def self.moderator_ids
    @moderator_ids ||= joins(:roles).where(roles: { name: 'Moderator' }).pluck(:id).to_set
  end

  def administrator?
    roles.where(name: 'Administrator').any?
  end

  def generate_webhook_secret
    self.webhook_secret = SecureRandom.hex(64)
  end

  def pretty_signin_methods
    return identity_providers_used.filter_map { |p| Identity.pretty_provider(p) }
  end

  def identity_providers_used
    return identities.map(&:provider).uniq
  end

  def github_identity_only?
    identity_providers_used == ['github']
  end

  def favorite_script_set
    return ScriptSet.where(favorite: true).find_by(user_id: id)
  end

  def serializable_hash(options = nil)
    sleazy = options&.[](:sleazy)
    h = super({ only: [:id, :name, :created_at] }.merge(options || {})).merge({
                                                                                url: Rails.application.routes.url_helpers.user_url(nil, self, **(sleazy ? { host: 'sleazyfork.org' } : {})),
                                                                              })
    # rename listable_scripts to scripts
    unless h['listable_scripts'].nil?
      h['scripts'] = h['listable_scripts']
      h.delete('listable_scripts')
    end
    return h
  end

  # Returns the user's preferred locale code, if we have that locale available, otherwise nil.
  def available_locale_code
    return nil if locale.nil?
    return nil unless locale.ui_available

    return locale.code
  end

  def non_locked_scripts
    return scripts.not_locked
  end

  def lock_all_scripts!(delete_type:, moderator: nil, automod: false, reason: nil, report: nil)
    raise 'Must specify a moderator' unless moderator || automod

    non_locked_scripts.each do |s|
      s.delete_reason = reason
      s.locked = true
      s.delete_type = delete_type
      s.save(validate: false)
      ModeratorAction.create!(moderator:, automod:, script: s, action_taken: :delete_and_lock, reason:, report:)
    end
  end

  def unlock_all_scripts!(moderator:, reason: nil)
    scripts.where(locked: true).find_each do |s|
      s.delete_reason = nil
      s.locked = false
      s.delete_type = nil
      s.save(validate: false)
      ModeratorAction.create!(moderator:, script: s, action_taken: :undelete_and_unlock, reason:)
    end
  end

  def confirmed_or_identidied?
    confirmed? || identities.any? || scripts.any?
  end

  def in_confirmation_period?
    created_at > 5.minutes.ago
  end

  def update_trusted_report!
    resolved_count = reports_as_reporter.resolved.count
    if resolved_count < 3
      update(trusted_reports: false)
    else
      upheld_count = reports_as_reporter.resolved_and_valid.count
      update(trusted_reports: (upheld_count.to_f / resolved_count) >= 0.75)
    end
  end

  def seen_announcement?(key)
    announcements_seen&.include?(key.to_s)
  end

  def announcement_seen!(key)
    (self.announcements_seen ||= []) << key
    save!
  end

  def ban!(moderator: nil, automod: false, reason: nil, report: nil, delete_comments: false, delete_scripts: false, private_reason: nil, ban_related: true)
    raise 'Must specify a moderator' unless moderator || automod

    return if banned?

    raise "Can't ban this user." unless bannable?

    User.transaction do
      ModeratorAction.create!(
        moderator:,
        automod:,
        user: self,
        action_taken: :ban,
        reason:,
        private_reason:,
        report:
      )
      update_columns(banned_at: Time.current)
      reports_as_reporter.unresolved.each { |reported_reports| reported_reports.dismiss!(moderator:, moderator_notes: 'User banned.') }
    end

    if ban_related
      User.not_banned.where(canonical_email:).find_each do |user|
        user.ban!(moderator:, automod:, reason:, delete_comments: delete_scripts, delete_scripts:, private_reason:, ban_related: false, report:)
      end
    end

    delete_all_comments!(by_user: moderator, automod:) if delete_comments
    lock_all_scripts!(reason:, report:, moderator:, automod:, delete_type: 'blanked') if delete_scripts

    Report.unresolved.where(item: self).find_each do |other_report|
      other_report.uphold!(moderator:)
    end

    return unless delete_scripts

    # Resolve any reports on the user's deleted scripts
    Report.unresolved.where(item: scripts).find_each do |other_report|
      other_report.uphold!(moderator:)
    end
  end

  def unban!(moderator:, reason: nil, undelete_scripts: false)
    return unless banned?

    User.transaction do
      ModeratorAction.create!(
        moderator:,
        user: self,
        action_taken: :unban,
        reason:
      )
      update_columns(banned_at: nil)
      unlock_all_scripts!(moderator:, reason:) if undelete_scripts
    end
  end

  def report_stats(ignore_report: nil)
    report_scope = reports_as_reporter
    report_scope = report_scope.where.not(id: ignore_report) if ignore_report
    stats = report_scope.group(:result).count
    {
      pending: stats[nil] || 0,
      dismissed: stats['dismissed'] || 0,
      upheld: stats['upheld'] || 0,
      fixed: stats['fixed'] || 0,
    }
  end

  def subscribed_to?(discussion)
    discussion_subscriptions.where(discussion:).any?
  end

  def subscribed_to_conversation?(conversation)
    conversation_subscriptions.where(conversation:).any?
  end

  # Override devise's method to send async. https://github.com/heartcombo/devise#activejob-integration
  def send_devise_notification(notification, *)
    devise_mailer.send(notification, self, *).deliver_later
  end

  def needs_to_recaptcha?
    scripts.not_deleted.where(created_at: ..1.month.ago).none? &&
      discussions.not_deleted.where(created_at: ..1.month.ago).none? &&
      comments.not_deleted.where(created_at: ..1.month.ago).none?
  end

  def existing_conversation_with(users)
    c = conversations
    users.each { |user| c = c.where(id: user.conversation_ids) }
    c.first
  end

  def delete_all_comments!(by_user: nil, automod: false)
    discussions.not_deleted.each { |discussion| discussion.soft_destroy!(by_user:) }
    comments.not_deleted.each { |comment| comment.soft_destroy!(by_user:) }
    Report.unresolved.where(item: discussions + comments).find_each { |report| report.uphold!(moderator: by_user, automod:) }
  end

  def banned?
    banned_at.present?
  end

  def update_stats!
    update_columns(calculate_stats)
  end

  def assign_stats
    assign_attributes(calculate_stats)
  end

  SCRIPT_STAT_QUERIES = [
    [:count, 'count(scripts.id)'],
    [:total_installs, 'coalesce(sum(scripts.total_installs), 0)'],
    [:daily_installs, 'coalesce(sum(scripts.daily_installs), 0)'],
    [:fan_score, 'coalesce(sum(scripts.fan_score), 0)'],
    [:last_created, 'max(scripts.created_at)'],
    [:last_updated, 'max(scripts.code_updated_at)'],
    [:ratings, 'coalesce(sum(scripts.good_ratings + scripts.ok_ratings + scripts.bad_ratings), 0)'],
  ].freeze
  SCRIPT_STAT_COLUMNS = %w[total_installs daily_installs fan_score created_at code_updated_at good_ratings ok_ratings bad_ratings].freeze

  def calculate_stats
    script_stat_results = scripts.listable(:all).pick(*SCRIPT_STAT_QUERIES.map(&:last).map { |v| Arel.sql(v) })
    script_stat_results = SCRIPT_STAT_QUERIES.map(&:first).each_with_index.to_h { |k, i| [k, script_stat_results[i]] }
    {
      stats_script_count: script_stat_results[:count],
      stats_script_total_installs: script_stat_results[:total_installs],
      stats_script_daily_installs: script_stat_results[:daily_installs],
      stats_script_fan_score: script_stat_results[:fan_score],
      stats_script_ratings: script_stat_results[:ratings],
      stats_script_last_created: script_stat_results[:last_created],
      stats_script_last_updated: script_stat_results[:last_updated],
    }
  end

  def subscribed_to_anything?
    subscribe_on_script_discussion ||
      subscribe_on_discussion ||
      subscribe_on_comment ||
      subscribe_on_conversation_starter ||
      subscribe_on_conversation_receiver ||
      discussion_subscriptions.any? ||
      conversation_subscriptions.any? ||
      UserNotificationSetting::DEFAULT_NOTIFICATIONS.keys.any? { |dn| UserNotificationSetting.delivery_types_for_user(self, dn).any? }
  end

  def any_email_notifications?
    UserNotificationSetting::DEFAULT_NOTIFICATIONS.keys.any? { |dn| UserNotificationSetting.delivery_types_for_user(self, dn).include?(UserNotificationSetting::DELIVERY_TYPE_EMAIL) }
  end

  def unsubscribe_all!
    update!(
      subscribe_on_script_discussion: false,
      subscribe_on_discussion: false,
      subscribe_on_comment: false,
      subscribe_on_conversation_starter: false,
      subscribe_on_conversation_receiver: false
    )
    UsersController::NOTIFICATION_KEYS.each do |notification_type|
      UserNotificationSetting.update_delivery_types_for_user(self, notification_type, [])
    end
    discussion_subscriptions.destroy_all
    conversation_subscriptions.destroy_all
  end

  def unsubscribe_email!
    UsersController::NOTIFICATION_KEYS.each do |notification_type|
      UserNotificationSetting.update_delivery_types_for_user(self, notification_type, UserNotificationSetting.delivery_types_for_user(self, notification_type) - [UserNotificationSetting::DELIVERY_TYPE_EMAIL])
    end
  end

  def blocked_from_reporting_until
    recent_reports = reports_as_reporter.resolved.where(created_at: 1.week.ago..).order(:created_at)
    recent_reports.first.created_at + 1.week if recent_reports.count(&:dismissed?) == 5
  end

  def bannable?
    !administrator? && !moderator?
  end

  def api_as_json(with_private_scripts: false)
    return as_json(include: :scripts) if with_private_scripts

    json = as_json
    json[:scripts] = all_listable_scripts.as_json
    json
  end

  # For use from console for people who can't receive emails.
  def generate_password_reset_link
    token = set_reset_password_token
    Rails.application.routes.url_helpers.edit_user_password_url(reset_password_token: token, locale: available_locale_code)
  end

  def uses_secure_login?
    otp_required_for_login || encrypted_password.nil?
  end

  def suggestable_secure_login?
    scripts.any?
  end

  def suggest_secure_login?
    !uses_secure_login? && suggestable_secure_login?
  end

  def require_secure_login?
    moderator? || (require_secure_login_for_author? && scripts.any?)
  end

  def missing_secure_login?
    !uses_secure_login? && require_secure_login?
  end

  def missing_secure_login_for_author?
    require_secure_login_for_author? && encrypted_password && (!confirmed? || !otp_required_for_login)
  end

  protected

  def password_required?
    new_record? && identities.empty?
  end

  # Overrides devise's method, as we do not require confirmation from all users.
  def confirmation_required?
    false
  end
end
