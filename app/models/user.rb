require 'securerandom'
require 'devise'
require 'digest'

class User < ApplicationRecord
  include MentionsUsers

  AUTHOR_NOTIFICATION_NONE = 1
  AUTHOR_NOTIFICATION_DISCUSSION = 2
  AUTHOR_NOTIFICATION_COMMENT = 3

  serialize :announcements_seen, Array

  scope :moderators, -> { joins(:roles).where(roles: { name: 'moderator' }) }
  scope :administrators, -> { joins(:roles).where(roles: { name: 'administrator' }) }

  scope :banned, -> { where.not(banned_at: nil) }
  scope :not_banned, -> { where(banned_at: nil) }

  has_many :authors, dependent: :destroy
  has_many :scripts, through: :authors
  has_many :reports_as_reporter, foreign_key: :reporter_id, inverse_of: :reporter, class_name: 'Report', dependent: nil
  has_many :discussions, foreign_key: 'poster_id', inverse_of: :poster, dependent: nil
  has_many :comments, foreign_key: 'poster_id', inverse_of: :poster, dependent: nil
  has_many :discussion_subscriptions, dependent: :destroy
  has_many :mentions_as_target, class_name: 'Mention', dependent: :destroy

  # Gotta to it this way because you can't pass a parameter to a has_many, and we need it has_many
  # to do eager loading.
  Script.subsets.each do |subset|
    has_many "#{subset}_listable_scripts".to_sym, -> { listable(subset) }, class_name: 'Script', through: :authors, source: :script
  end

  has_and_belongs_to_many :roles, dependent: :destroy

  has_many :identities, dependent: :destroy

  has_many :script_sets, dependent: :destroy

  belongs_to :locale, optional: true

  has_and_belongs_to_many :conversations
  has_many :conversation_subscriptions, dependent: :destroy

  ThinkingSphinx::Callbacks.append(self, :script, behaviours: [:sql, :deltas], path: [:scripts])

  before_destroy(prepend: true) do
    scripts.select { |script| script.authors.where.not(user_id: id).none? }.each(&:destroy!)
  end

  BANNED_EMAIL_SALT = '95b68f92d7f373b07dfe101a4b3b46708ae161739b263016eefa3d01762879936507ff2a55442e9a47c681d895de4d905565e2645caff432a987b07457bc005b'.freeze

  after_destroy do
    next unless canonical_email && banned_at

    hash = Digest::SHA1.hexdigest(BANNED_EMAIL_SALT + canonical_email)
    BannedEmailHash.create(email_hash: hash, deleted_at: Time.current, banned_at: banned_at) unless BannedEmailHash.where(email_hash: hash).any?
  end

  def self.email_previously_banned_and_deleted?(email)
    return false unless email

    email = EmailAddress.canonical(email)
    hash = Digest::SHA1.hexdigest(BANNED_EMAIL_SALT + email)
    BannedEmailHash.where(email_hash: hash).any?
  end

  before_validation do
    self.canonical_email = EmailAddress.canonical(email)
  end

  before_save do
    self.email_domain = email ? email.split('@').last : nil
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

  # Include default devise modules. Others available are:
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable, :confirmable

  # Prevent session termination vulnerability
  # https://makandracards.com/makandra/53562-devise-invalidating-all-sessions-for-a-user
  def authenticatable_salt
    "#{super}#{session_token}"
  end

  def invalidate_all_sessions!
    self.session_token = SecureRandom.hex
  end

  validates :name, :profile_markup, :preferred_markup, presence: true
  validates :name, uniqueness: { case_sensitive: false }, length: { minimum: 1, maximum: 50 }
  validates :profile, length: { maximum: 10_000 }
  validates :profile_markup, inclusion: { in: %w[html markdown] }
  validates :preferred_markup, inclusion: { in: %w[html markdown] }
  validates :author_email_notification_type_id, inclusion: { in: [AUTHOR_NOTIFICATION_NONE, AUTHOR_NOTIFICATION_DISCUSSION, AUTHOR_NOTIFICATION_COMMENT] }

  validate do
    errors.add(:email) if new_record? && identities.none? && !EmailAddress.valid?(email)
  end

  validate do
    errors.add(:email) if new_record? && email && SpammyEmailDomain.where(domain: email.split('@').last, block_type: SpammyEmailDomain::BLOCK_TYPE_REGISTER).any?
  end

  validate do
    errors.add(:base, 'This email has been banned.') if (new_record? || email_changed? || unconfirmed_email_changed?) && (User.banned.where(canonical_email: canonical_email).any? || User.email_previously_banned_and_deleted?(canonical_email))
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

  def favorite_script_set
    return ScriptSet.where(favorite: true).find_by(user_id: id)
  end

  def serializable_hash(options = nil)
    h = super({ only: [:id, :name] }.merge(options || {})).merge({
                                                                   url: Rails.application.routes.url_helpers.user_url(nil, self),
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

  def lock_all_scripts!(moderator:, delete_type:, reason: nil, report: nil)
    non_locked_scripts.each do |s|
      s.delete_reason = reason
      s.locked = true
      s.script_delete_type_id = delete_type
      s.save(validate: false)
      ModeratorAction.create!(moderator: moderator, script: s, action: 'Delete and lock', reason: reason, report: report)
    end
  end

  def confirmed_or_identidied?
    confirmed? || identities.any?
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

  def ban!(moderator:, reason: nil, report: nil, delete_comments: false, delete_scripts: false, private_reason: nil, ban_related: true)
    return if banned?

    User.transaction do
      ModeratorAction.create!(
        moderator: moderator,
        user: self,
        action: 'Ban',
        reason: reason,
        private_reason: private_reason,
        report: report
      )
      update_columns(banned_at: Time.current)
      reports_as_reporter.unresolved.each { |reported_reports| reported_reports.dismiss!(moderator_notes: 'User banned.') }
    end

    if ban_related
      User.not_banned.where(canonical_email: canonical_email).find_each do |user|
        user.ban!(moderator: moderator, reason: reason, delete_comments: delete_scripts, delete_scripts: delete_scripts, private_reason: private_reason, ban_related: false, report: report)
      end
    end

    delete_all_comments!(by_user: moderator) if delete_comments
    lock_all_scripts!(reason: reason, report: report, moderator: moderator, delete_type: ScriptDeleteType::BLANKED) if delete_scripts

    Report.unresolved.where(item: self).find_each do |other_report|
      other_report.uphold!(moderator: moderator)
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
    discussion_subscriptions.where(discussion: discussion).any?
  end

  def subscribed_to_conversation?(conversation)
    conversation_subscriptions.where(conversation: conversation).any?
  end

  # Override devise's method to send async. https://github.com/heartcombo/devise#activejob-integration
  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

  def needs_to_recaptcha?
    scripts.not_deleted.where('created_at <= ?', 1.month.ago).none?
  end

  def existing_conversation_with(users)
    c = conversations
    users.each { |user| c = c.where(id: user.conversation_ids) }
    c.first
  end

  def delete_all_comments!(by_user: nil)
    discussions.not_deleted.each { |comment| comment.soft_destroy!(by_user: by_user) }
    comments.not_deleted.each { |comment| comment.soft_destroy!(by_user: by_user) }
    Report.unresolved.where(item: comments).find_each { |report| report.uphold!(moderator: by_user) }
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

  def calculate_stats
    script_stat_results = scripts.listable(:all).pick(*SCRIPT_STAT_QUERIES.map(&:last).map { |v| Arel.sql(v) })
    script_stat_results = SCRIPT_STAT_QUERIES.map(&:first).each_with_index.map { |k, i| [k, script_stat_results[i]] }.to_h
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

  protected

  def password_required?
    new_record? && identities.empty?
  end

  def confirmation_required?
    false
  end
end
