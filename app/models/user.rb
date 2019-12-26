require 'securerandom'
require 'devise'

class User < ApplicationRecord
  self.ignored_columns = %w(approve_redistribution)

  serialize :announcements_seen, Array

  scope :administrators, -> { joins(:roles).where(roles: { name: 'administrator' }) }

  has_many :authors, dependent: :destroy
  has_many :scripts, through: :authors
  has_many :script_reports, foreign_key: 'reporter_id'

  # Gotta to it this way because you can't pass a parameter to a has_many, and we need it has_many
  # to do eager loading.
  Script.subsets.each do |subset|
    has_many "#{subset}_listable_scripts".to_sym, -> { listable(subset) }, class_name: 'Script', through: :authors, source: :script
  end

  #this results in a cartesian join when included with the scripts relation
  #has_many :discussions, through: :scripts

  has_and_belongs_to_many :roles, dependent: :destroy

  has_many :identities, dependent: :destroy

  has_many :script_sets, dependent: :destroy

  belongs_to :locale, optional: true

  has_and_belongs_to_many :forum_users, -> { readonly }, :foreign_key => 'ForeignUserKey', :association_foreign_key => 'UserID', :join_table => 'GDN_UserAuthentication'

  def forum_user
    return forum_users.first
  end

  before_destroy(prepend: true) do
    throw(:abort) if !can_be_deleted?
    forum_user.rename_on_delete! if forum_user.present?
    scripts.select { |script| script.authors.where.not(user_id: id).none? }.each(&:destroy!)
  end

  before_validation do
    self.canonical_email = EmailAddress.canonical(email)
  end

  # Include default devise modules. Others available are:
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable, :confirmable

  validates_presence_of :name, :profile_markup, :preferred_markup
  validates_uniqueness_of :name, case_sensitive: false
  validates_length_of :profile, :maximum => 10000
  validates_inclusion_of :profile_markup, :in => ['html', 'markdown']
  validates_inclusion_of :preferred_markup, :in => ['html', 'markdown']
  validates_with DisallowedAttributeValidator, object_type: :user

  validate on: :create do
    errors.add(:base, "This account has been banned.") if User.where(banned: true, canonical_email: canonical_email).any?
  end

  # Devise runs this when password_required?, and we override that so
  # that users don't have to deal with passwords all the time. Add it
  # back when Devise won't run it and the user is actually setting the
  # password.
  validates_confirmation_of :password, if: Proc.new{|u| !u.password_required? && !u.password.nil?}

  strip_attributes

  def discussions_on_scripts_written
    ForumDiscussion.where(ScriptID: script_ids).order(Arel.sql('COALESCE(DateLastComment, DateInserted) DESC'))
  end

  def slugify(name)
    # take out swears
    r = name.downcase.gsub(/motherfucking|motherfucker|fucking|fucker|fucks|fuck|shitty|shits|shit|niggers|nigger|cunts|cunt/, '')
    # multiple non-alphas into one
    r.gsub!(/([^[:alnum:]])[^[:alnum:]]+/) {|s| $1}
    # leading non-alphas
    r.gsub!(/^[^[:alnum:]]+/, '')
    # trailing non-alphas
    r.gsub!(/[^[:alnum:]]+$/, '')
    # non-alphas into dashes
    r.gsub!(/[^[:alnum:]]/, '-')
    # use "user" if we don't have something suitable
    r = 'user' if r.empty?
    return r
  end

  def to_param
    "#{id}-#{slugify(name)}"
  end

  def moderator?
    roles.where(name: 'Moderator').any?
  end

  def administrator?
    roles.where(name: 'Administrator').any?
  end

  def generate_webhook_secret
    self.webhook_secret = SecureRandom.hex(64)
  end

  def pretty_signin_methods
    return identity_providers_used.map{|p| Identity.pretty_provider(p)}.compact
  end

  def identity_providers_used
    return self.identities.map{|i| i.provider}.uniq
  end

  def favorite_script_set
    return ScriptSet.where(:favorite => true).where(:user_id => id).first
  end

  def serializable_hash(options = nil)
    h = super({ only: [:id, :name] }.merge(options || {})).merge({
                                                                     :url => Rails.application.routes.url_helpers.user_url(nil, self)
                                                                 })
    # rename listable_scripts to scripts
    if !h['listable_scripts'].nil?
      h['scripts'] = h['listable_scripts']
      h.delete('listable_scripts')
    end
    return h
  end

  # Returns the user's preferred locale code, if we have that locale available, otherwise nil.
  def available_locale_code
    return nil if locale.nil?
    return nil if !locale.ui_available
    return locale.code
  end

  def non_locked_scripts
    return scripts.select{|s| !s.locked}
  end

  def can_be_deleted?
    return scripts.all(&:immediate_deletion_allowed?)
  end

  def posting_permission
    # Assume identity providers are good at stopping bots.
    return :allowed if identities.any?
    return :allowed if email.blank?

    sed = SpammyEmailDomain.find_by(domain: email.split('@').last)
    if sed
      return :blocked if sed.complete_block?
      return :needs_confirmation if in_confirmation_period?
    end

    return :needs_confirmation unless confirmed?

    :allowed
  end

  def in_confirmation_period?
    created_at > 5.minutes.ago
  end

  def update_trusted_report!
    resolved_count = script_reports.resolved.count
    if resolved_count < 3
      update(trusted_reports: false)
    else
      upheld_count = script_reports.upheld.count
      update(trusted_reports: (upheld_count.to_f / resolved_count.to_f) >= 0.75)
    end
  end

  def seen_announcement?(key)
    announcements_seen&.include?(key.to_s)
  end

  def announcement_seen!(key)
    (self.announcements_seen ||= []) << key
    save!
  end

  protected

  def password_required?
    self.new_record? && self.identities.empty?
  end

  def confirmation_required?
    false
  end
end
