# frozen_string_literal: true

require 'localizing_model'
require 'css_to_js_converter'

class Script < ApplicationRecord
  self.ignored_columns += %w[disable_stats]

  include LocalizingModel
  include DetectsLocale
  include ScriptIndexing

  CONSECUTIVE_BAD_RATINGS_COUNT = 3
  CONSECUTIVE_BAD_RATINGS_GRACE_PERIOD = 2.weeks
  CONSECUTIVE_BAD_RATINGS_NOTIFICATION_DELAY = 1.day

  enum :delete_type, { 'keep' => 1, 'blanked' => 2, 'redirect' => 3 }, prefix: true
  enum :script_type, { 'public' => 1, 'unlisted' => 2, 'library' => 3 }, prefix: true
  enum :sync_type, { 'manual' => 1, 'automatic' => 2, 'webhook' => 3 }, prefix: true

  belongs_to :promoted_script, class_name: 'Script', optional: true

  has_many :authors, -> { order(:id) }, dependent: :destroy, inverse_of: :script
  has_many :users, through: :authors
  has_many :script_versions, dependent: :destroy
  has_many :script_applies_tos, dependent: :destroy, autosave: true
  has_many :site_applications, through: :script_applies_tos
  has_many :discussions, dependent: :destroy
  has_many :comments, through: :discussions
  has_many :script_set_script_inclusions, foreign_key: 'child_id', dependent: :destroy, inverse_of: :child
  has_many :favorited_in_sets, -> { includes(:users).where(favorite: true) }, through: :script_set_script_inclusions, class_name: 'ScriptSet', source: 'parent'
  has_many :favoriters, through: :favorited_in_sets, class_name: 'User', source: 'user'
  has_many :localized_attributes, class_name: 'LocalizedScriptAttribute', autosave: true, dependent: :destroy
  has_many :localized_names, -> { where(attribute_key: 'name') }, class_name: 'LocalizedScriptAttribute', inverse_of: :script
  has_many :localized_descriptions, -> { where(attribute_key: 'description') }, class_name: 'LocalizedScriptAttribute', inverse_of: :script
  has_many :localized_additional_infos, -> { where(attribute_key: 'additional_info') }, class_name: 'LocalizedScriptAttribute', inverse_of: :script
  has_many :compatibilities, autosave: true, dependent: :destroy
  has_many :script_invitations, dependent: :destroy
  has_many :script_similarities, dependent: :destroy
  has_many :forum_discussions, foreign_key: 'ScriptID', inverse_of: :script
  has_many :antifeatures, dependent: :destroy, autosave: true
  has_many :reports, as: :item, dependent: :destroy
  has_many :reports_as_reference_script, class_name: 'Report', foreign_key: :reference_script_id, inverse_of: :reference_script, dependent: :destroy
  has_many :script_lock_appeals, dependent: :destroy
  has_many :subresource_usages, dependent: :destroy, class_name: 'ScriptSubresourceUsage', autosave: true
  has_many :subresources, through: :subresource_usages
  has_many :notifications, inverse_of: :item, dependent: :destroy
  has_many :stat_bans, dependent: :destroy

  has_one :cleaned_code, dependent: :delete

  belongs_to :license, optional: true
  belongs_to :locale
  belongs_to :replaced_by_script, class_name: 'Script', optional: true
  belongs_to :marked_adult_by_user, class_name: 'User', optional: true
  belongs_to :delete_report, class_name: 'Report', optional: true

  attr_accessor :adult_content_self_report, :not_adult_content_self_report

  delegate :meta, to: :newest_saved_script_version

  scope :not_deleted, -> { where(delete_type: nil) }
  scope :deleted, -> { where.not(delete_type: nil) }
  scope :active, lambda { |script_subset|
    f = not_deleted
    case script_subset
    when :greasyfork
      f.where(sensitive: false)
    when :sleazyfork
      f.where(sensitive: true)
    when :all
      f
    else
      raise ArgumentError, "Invalid argument #{script_subset}"
    end
  }
  scope :listable, ->(script_subset) { active(script_subset).where(script_type: :public).where.not(review_state: 'required') }
  scope :libraries, ->(script_subset) { active(script_subset).where(script_type: :library) }
  scope :listable_including_libraries, ->(script_subset) { active(script_subset).where(script_type: [:public, :library]) }
  scope :reported, -> { not_deleted.joins(:reports).where(reports: { result: nil }).distinct }
  scope :reported_not_adult, -> { not_deleted.includes(:users).where.not(not_adult_content_self_report_date: nil) }
  scope :for_all_sites, -> { includes(:script_applies_tos).references(:script_applies_tos).where('script_applies_tos.id' => nil) }
  scope :locked, -> { where(locked: true) }
  scope :not_locked, -> { where.not(locked: true) }
  scope :with_includes_for_show, -> { includes(users: {}, license: {}, localized_attributes: :locale, compatibilities: :browser, script_applies_tos: :site_application, antifeatures: :locale) }
  scope :with_bad_integrity_hashes, -> { joins(:subresource_usages).joins('INNER JOIN subresource_integrity_hashes sih ON script_subresource_usages.subresource_id = sih.subresource_id AND script_subresource_usages.algorithm = sih.algorithm AND script_subresource_usages.encoding = sih.encoding AND script_subresource_usages.integrity_hash != sih.integrity_hash').distinct }

  # Must have a default name and description
  validates :default_name, presence: { message: :script_missing_name, unless: proc { |s| s.library? } }
  validates :name, presence: true, if: ->(s) { s.library? }
  validates :description, presence: { message: :script_missing_description, unless: proc { |r| r.deleted? || r.library? } }
  validates :description, presence: { unless: proc { |r| r.deleted? || !r.library? } }
  validates :description, exclusion: { in: ['try to take over the world!'], message: :invalid }, on: :create
  validates :language, presence: true, inclusion: %w[js css]
  validates :license_text, length: { maximum: 500 }, allow_nil: true

  validate do |script|
    next unless script.library?

    errors.add(:name, :taken) if Script.where.not(id: script.id).where(default_name: script.name).any?
  end

  RATE_LIMITS = {
    1.hour => 5,
    1.day => 10,
  }.freeze

  validate on: :create do |script|
    next if Rails.env.test?

    errors.add(:base, :script_rate_limit) if RATE_LIMITS.any? { |period, count| script.users.sum { |u| u.scripts.where(['created_at > ?', period.ago]).count } >= count }
  end

  MAX_LENGTHS = { name: 100, description: 500, additional_info: 50_000 }.freeze
  LOCALIZED_ATTRIBUTES_FROM_META = [:name, :description].freeze
  validates_each(*MAX_LENGTHS.keys) do |script, attr, _|
    len = MAX_LENGTHS[attr]
    if script.localized_attributes_for(attr)
             .reject { |la| la.attribute_value.nil? }
             .find { |la| la.attribute_value.length > len }
      if LOCALIZED_ATTRIBUTES_FROM_META.include?(attr) && !script.library?
        script.errors.add(:base, :too_long, message: I18n.t('errors.messages.meta_too_long', count: len, key: "@#{attr}"))
      else
        script.errors.add(attr, :too_long, message: I18n.t('errors.messages.too_long', count: len))
      end
    end
  end

  # Every locale that provides a name must have a description that's different than the name
  validate do |script|
    localized_names = script.localized_attributes_for('name')
    localized_descriptions = script.localized_attributes_for('description')
    localized_names.each do |ln|
      matching_description = localized_descriptions.find { |ld| ld.locale == ln.locale }
      validation_key = script.library? ? :description : LocalizedScriptAttribute.localized_meta_key(:description, ln.locale, false)
      if matching_description.nil?
        script.errors.add(validation_key, I18n.t('errors.messages.blank'))
      elsif matching_description.attribute_value == ln.attribute_value
        script.errors.add(validation_key, I18n.t('errors.messages.script_name_same_as_description'))
      end
    end
  end

  validates_each :localized_attributes do |s, attr, children|
    s.errors.delete(attr)
    children.each do |child|
      child.errors.attribute_names.each { |key| s.errors.delete("#{attr}.#{key}") }
      next if child.marked_for_destruction? || child.valid?

      child.errors.each do |error|
        s.errors.add(:base, error.type, message: "#{I18n.t("activerecord.attributes.script.#{child.attribute_key}")} - #{I18n.t("activerecord.attributes.script.#{error.attribute}", default: error.attribute.to_s)} #{error.message}")
      end
    end
  end

  validates :code_updated_at, presence: true

  validates :sync_identifier, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: :script_sync_identifier_bad_protocol }, allow_nil: true, unless: -> { Rails.env.test? }

  validates :sync_identifier, length: { maximum: 500 }

  # Private use area unicode
  validates_each :name, :description, :additional_info do |script, attr, value|
    script.errors.add(attr, :invalid) if /[\u{e000}-\u{f8ff}\u{f0000}-\u{fffff}\u{100000}-\u{10ffff}]/.match?(value)
  end

  strip_attributes only: [:sync_identifier]

  before_validation :set_default_name
  def set_default_name
    self.default_name = default_localized_value_for('name')
    true
  end

  before_validation :set_locale
  def set_locale
    return unless locale.nil?

    # Try to avoid doing this for something that will be invalid anyway.
    # The API is limited.
    return if description.blank?

    self.locale = detect_locale
    localized_attributes.select { |la| la.locale.nil? }.each { |la| la.locale = locale }
    true
  end

  # If the locale has changed, update the default localized attributes' locale
  before_validation :update_localized_attribute_locales, on: :create
  def update_localized_attribute_locales
    return unless locale_id_changed?

    # For new records, we just set the default locale
    localized_attributes.select(&:attribute_default).each { |la| la.locale = locale }
  end

  before_validation :update_localized_attribute_locales_for_existing, on: :update
  def update_localized_attribute_locales_for_existing
    # All existing scripts should have a locale; this is getting called on test setup without a locale.
    return unless locale_id_changed? && locale_id_was

    # For existing records, recalculate because if they had @name and @name:fr with a default locale of fr, changing the
    # default locale not only updates the locale of the default attributes, but also adds new non-default fr attributes.
    %w[name description].each { |key| update_localized_attribute(meta, key) } unless library?
  end

  before_validation :set_sensitive_flag
  def set_sensitive_flag
    if sensitive
      self.sensitive = false if not_adult_content_self_report_date && marked_adult_by_user && !marked_adult_by_user&.moderator?
    elsif for_sensitive_site?(unsaved: true) || adult_content_self_report
      self.sensitive = true
    end
  end

  before_save do
    unless sensitive
      self.not_adult_content_self_report_date = nil
      self.marked_adult_by_user = nil
    end
  end

  def matching_sensitive_sites(unsaved: false)
    sa = unsaved ? script_applies_tos.map(&:site_application).select(&:domain?).map(&:domain_text) : site_applications.domain.pluck(:domain_text)
    SensitiveSite.where(domain: sa)
  end

  def for_sensitive_site?(unsaved: false)
    return matching_sensitive_sites(unsaved:).any?
  end

  before_destroy do |script|
    %w[install_counts daily_install_counts update_check_counts daily_update_check_counts].each do |table|
      script.class.connection.execute "DELETE FROM #{table} WHERE script_id = #{script.id}"
    end
  end

  after_create_commit do |script|
    # Increase the priority on this job because it's a new script. ScriptPreviouslyDeletedChecker runs off of this call
    # and we want that to happen quickly.
    ScriptDuplicateCheckerJob.set(queue: 'default').perform_async(script.id)
  end

  # Check saved_change_to to determine whether to run, but have to run after_commit for the changes to be visible to the
  # Job.
  after_update do |script|
    @_code_changed = script.saved_change_to_code_updated_at?
  end

  after_update_commit do |script|
    if @_code_changed
      ScriptDuplicateCheckerJob.perform_async(script.id) unless Rails.env.development?
      clear_latest_cached_code
    end
    @_code_changed = false
  end

  after_commit do
    users.each(&:update_stats!) if previous_changes.slice(*User::SCRIPT_STAT_COLUMNS).any?
  end

  after_commit on: :update do
    comments.reindex if saved_change_to_attribute?('delete_type') && !Rails.env.test?
  end

  after_save do
    next unless saved_change_to_attribute?('delete_type')

    discussions.find_each do |d|
      d.calculate_publicly_visible
      d.save
    end
  end

  before_save do |script|
    if script.deleted?
      script.deleted_at ||= Time.current
    else
      script.deleted_at = nil
    end
  end

  def apply_from_script_version(script_version)
    # Copy additional_info from script versions. Retain syncing info.
    original_script_las = localized_attributes_for('additional_info').to_a
    # Try to retain the records - search by locale
    script_version.localized_attributes_for('additional_info').each do |sv_la|
      matching_osla = original_script_las.find { |osla| osla.locale_id == sv_la.locale_id }
      if matching_osla.nil?
        # New
        build_localized_attribute(sv_la)
      else
        matching_osla.value_markup = sv_la.value_markup
        matching_osla.attribute_value = sv_la.attribute_value
        # We've found this one, don't search for it any more.
        original_script_las.delete(matching_osla)

        # Add any missing mentions
        sv_la.mentions.each do |mention|
          matching_osla.mentions.build(user_id: mention.user_id, text: mention.text) if matching_osla.mentions.none? { |matching_mention| matching_mention.user_id == mention.user_id && matching_mention.text == mention.text }
        end

        # Remove any unneeded mentions
        matching_osla.mentions
                     .reject(&:new_record?)
                     .reject { |mention| sv_la.mentions.any? { |matching_mention| matching_mention.user_id == mention.user_id && matching_mention.text == mention.text } }
                     .each(&:mark_for_destruction)
      end
    end
    # Delete any that are gone
    original_script_las.each(&:mark_for_destruction)

    meta = script_version.parser_class.parse_meta(script_version.rewritten_code)

    # Don't use meta @name or @description for existing libraries - we are showing text boxes for that.
    %w[name description].each { |key| update_localized_attribute(meta, key) } unless library? && !new_record?

    localized_attributes_for('description').select { |la| la.attribute_value.length > MAX_LENGTHS[:description] }.each { |la| la.attribute_value = la.attribute_value[0, MAX_LENGTHS[:description]] } if script_version.truncate_description

    unless library?
      applies_to_names = script_version.calculate_applies_to_names
      applies_to_delete = script_applies_tos.reject { |sat| applies_to_names.any? { |atn| sat.text == atn[:text] && sat.tld_extra == atn[:tld_extra] && sat.domain? == atn[:domain] } }
      applies_to_delete.each(&:mark_for_destruction)
      applies_to_add = applies_to_names.reject { |atn| script_applies_tos.any? { |sat| sat.text == atn[:text] && sat.tld_extra == atn[:tld_extra] && sat.domain? == atn[:domain] } }

      existing_site_applications = SiteApplication.where(text: applies_to_add.pluck(:text))
      applies_to_add.each do |atn|
        site_application = existing_site_applications.find { |esa| esa.text == atn[:text] && esa.domain? == atn[:domain] } || SiteApplication.new(text: atn[:text], domain_text: atn[:domain] ? atn[:text] : nil)
        script_applies_tos.build(site_application:, tld_extra: atn[:tld_extra])
      end
    end

    if new_record? || code_updated_at.nil?
      self.code_updated_at = Time.current
    else
      newest_sv = newest_saved_script_version
      self.code_updated_at = Time.current if newest_sv.nil? || (newest_sv.code != script_version.code)
    end

    update_license(meta['license']&.first)
    self.namespace = meta['namespace']&.first
    self.version = script_version.version
    self.not_js_convertible_override = script_version.not_js_convertible_override

    self.contribution_url = meta.key?('contributionURL') ? meta['contributionURL'].find { |url| URI::DEFAULT_PARSER.make_regexp(%w[http https bitcoin]) =~ url } : nil
    self.contribution_amount = (!contribution_url.nil? && meta.key?('contributionAmount')) ? meta['contributionAmount'].first : nil

    self.support_url = if meta.key?('supportURL')
                         meta['supportURL'].find do |url|
                           next false if url.size > 500
                           # mailto is always OK
                           next true if URI::DEFAULT_PARSER.make_regexp(%w[mailto])&.match?(url)
                           # http(s) is also OK
                           next false unless URI::DEFAULT_PARSER.make_regexp(%w[http https])&.match?(url)

                           # avoid self-linking, there's UI on the same page for discussions
                           begin
                             next URI(url).host != 'greasyfork.org'
                           rescue StandardError
                             next false
                           end
                         end
                       end

    self.css_convertible_to_js = css? && !not_js_convertible_override && CssToJsConverter.convertible?(script_version.rewritten_code)

    new_compatibility_data = []
    %w[compatible incompatible].each do |key|
      next unless meta.key?(key)

      compatible = key == 'compatible'
      meta[key].each do |line|
        browser_match = /\A([a-z]+).*/i.match(line)
        next if browser_match.nil?

        browser = Browser.find_by(code: browser_match[1].downcase)
        next if browser.nil?

        comments_split = line.split(' ', 2)
        comments = (comments_split.length == 2) ? comments_split[1] : nil
        new_compatibility_data << { compatible:, browser:, comments: }
      end
    end
    update_children(:compatibilities, new_compatibility_data)

    new_antifeature_data = []
    meta.select { |key, _values| key.starts_with?('antifeature') }.each do |key, values|
      values.each do |value|
        _, locale_key = key.split(':', 2)
        locale = locale_key.presence && Locale.find_by(code: locale_key)
        type, description = value.split(/\s+/, 2)
        next unless Antifeature.antifeature_types.include?(type)

        new_antifeature_data << { locale:, antifeature_type: type, description: }
      end
    end
    update_children(:antifeatures, new_antifeature_data)

    new_subresource_data = []
    [meta['require'], meta['resource']&.map { |v| v.split(/\s+/, 2).last }]
      .flatten
      .compact
      .uniq
      .each do |url|
      next unless url.starts_with?('https:') || url.starts_with?('http:')

      url, integrity_hashes = url.split('#', 2)
      if integrity_hashes
        integrity_hashes = integrity_hashes.split(/[;,]/, 2)
        integrity_hashes = integrity_hashes.map { |entry| entry.split(/[=-]/, 2) }
        integrity_hashes = integrity_hashes.select { |algorithm, hash| algorithm.present? && hash.present? }
      end
      subresource = Subresource.find_or_initialize_by(url:)
      if integrity_hashes&.any?
        integrity_hashes.each { |algorithm, hash| new_subresource_data << { subresource:, algorithm:, encoding: /\A[0-9a-f]+\z/.match?(hash) ? 'hex' : 'base64', integrity_hash: hash } }
      else
        new_subresource_data << { subresource: }
      end
    end
    update_children(:subresource_usages, new_subresource_data)
  end

  def newest_saved_script_version
    return script_versions.order(:id).last unless script_versions.loaded?

    # get the most recently saved record
    script_versions.reverse_each do |sv|
      return sv unless sv.new_record?
    end
    return nil
  end

  def current_code
    newest_saved_script_version&.code
  end

  def self.record_install(id, ip)
    Script.connection.execute("INSERT IGNORE INTO daily_install_counts (script_id, ip) VALUES (#{Script.connection.quote_string(id)}, '#{Script.connection.quote_string(ip)}');")
  end

  def active?
    !deleted?
  end

  def library?
    script_type_library?
  end

  def listable?
    active? && public?
  end

  def public?
    script_type_public?
  end

  def unlisted?
    script_type_unlisted?
  end

  def can_be_added_to_set?
    public? || unlisted?
  end

  def name(lookup_locale = nil)
    return localized_value_for('name', lookup_locale)
  end

  def description(lookup_locale = nil)
    return localized_value_for('description', lookup_locale)
  end

  def additional_info(lookup_locale = nil)
    return localized_value_for('additional_info', lookup_locale)
  end

  def additional_info_markup(lookup_locale = nil)
    la = localized_attribute_for('additional_info', lookup_locale)
    return nil if la.nil?

    return la.value_markup
  end

  # Full name minus URL-y characters
  def url_name
    return (name || default_name).gsub(%r{[?&/\#.]+}, '')
  end

  def to_param
    slug = slugify(default_name || name)
    return id.to_s if slug.blank?

    "#{id}-#{slug}"
  end

  def deleted?
    !delete_type.nil?
  end

  def update_license(text)
    if text.blank?
      self.license = nil
      self.license_text = nil
      return
    end

    text = text.strip
    license_entry = License.find_by(['code = ? OR name = ?', text, text])
    if license_entry
      self.license = license_entry
      self.license_text = nil
      return
    end

    self.license = nil
    self.license_text = text
  end

  def host_arg(sleazy: false)
    ((sleazy && sensitive) ? { host: 'sleazyfork.org' } : {})
  end

  def update_host(sleazy: false)
    return Rails.env.production? ? 'update.sleazyfork.org' : 'update.sleazyfork.local' if sleazy && sensitive

    Rails.env.production? ? 'update.greasyfork.org' : 'update.greasyfork.local'
  end

  def url(locale: nil, sleazy: false)
    url_helpers.script_url(self, locale:, **host_arg(sleazy:))
  end

  def code_url(sleazy: false, format_override: nil, version_id: nil)
    "https://#{update_host(sleazy:)}#{code_path(format_override:, version_id:)}"
  end

  def code_path(format_override: nil, version_id: nil)
    version_id = nil if version_id == 0

    extension = if library?
                  '.js'
                elsif ['meta.js', 'meta.css'].include?(format_override)
                  ".#{format_override}"
                elsif js? || format_override == 'js'
                  '.user.js'
                else
                  '.user.css'
                end

    # We want a nice filename for two reasons:
    # 1. After installing, the browser console will associate any errors/logs for the script with the filename.
    # 2. Greasemonkey requires the URL ends with .user.js. If you include query params, it doesn't recognize it.
    #    https://github.com/greasemonkey/greasemonkey/issues/1683

    # Limit to 255 bytes so that when the request comes, we can create a filename for the cache
    filename = url_name.mb_chars.limit(255 - extension.mb_chars.length).to_s

    filename = CGI.escapeURIComponent(filename)

    return "/scripts/#{id}/#{version_id || newest_saved_script_version.id}/#{filename}#{extension}" if library?

    return "/scripts/#{id}/#{version_id}/#{filename}#{extension}" if version_id

    "/scripts/#{id}/#{filename}#{extension}"
  end

  def feedback_path(locale: nil)
    url_helpers.feedback_script_path(self, locale:)
  end

  def serializable_hash(options = nil)
    sleazy = options&.[](:sleazy)
    super(
      {
        only: [:id, :daily_installs, :total_installs, :fan_score, :good_ratings, :ok_ratings, :bad_ratings, :created_at, :code_updated_at, :namespace, :support_url, :contribution_url, :contribution_amount],
      }.merge(options || {}))
      .merge({
               name: default_name,
               description: default_localized_value_for('description'),
               url: url(sleazy:),
               code_url: code_url(sleazy:),
               license: license&.name || license_text,
               version:,
               locale: locale&.code,
               deleted: deleted?,
             })
  end

  # all text content of non-localized attributes for this script (for language detection)
  def full_text
    parts = []
    parts << name if name.present?
    parts << default_name if default_name.present?
    parts << description if description.present?
    la = localized_attributes.find { |l| l.attribute_key == 'additional_info' && l.attribute_default }
    unless la.nil?
      additional_text = ApplicationController.helpers.format_user_text_as_plain(la.attribute_value, la.value_markup)
      parts << additional_text if additional_text.present?
    end
    return nil if parts.empty?

    return parts.join("\n")
  end

  def ban_all_authors!(moderator:, reason:, private_reason: nil)
    users.each do |user|
      user.ban!(moderator:, reason:, private_reason:)
      user.lock_all_scripts!(reason:, moderator:, delete_type: 'blanked')
      user.scripts.each { |script| Report.uphold_pending_reports_for(script) }
    end
  end

  def js?
    language == 'js'
  end

  def css?
    language == 'css'
  end

  def pending_report_by_trusted_reporter?
    reports.block_on_pending.any?
  end

  def review_required?
    review_state == 'required'
  end

  def script_versions_with_identical_code
    hashes = script_versions.joins(:script_code, :rewritten_script_code).pluck('script_codes.code_hash', 'rewritten_script_codes_script_versions.code_hash').flatten.uniq
    script_code_ids = ScriptCode.where(code_hash: hashes.uniq).pluck(:id)
    ScriptVersion
      .joins(:script)
      .merge(Script.not_deleted)
      .where.not(script_id: id)
      .where(['script_code_id IN (?) OR rewritten_script_code_id IN (?)', script_code_ids, script_code_ids])
  end

  def self.subsets
    [:greasyfork, :sleazyfork, :all]
  end

  def consecutive_bad_ratings?
    recent_ratings = discussions
                     .not_deleted
                     .with_actual_rating
                     .where('created_at < ? OR rating != ?', CONSECUTIVE_BAD_RATINGS_NOTIFICATION_DELAY.ago, Discussion::RATING_BAD)
                     .where(created_at: code_updated_at..)
                     .reorder(:created_at)
                     .last(CONSECUTIVE_BAD_RATINGS_COUNT)
                     .reject(&:author_posted?)
                     .map(&:rating)
    recent_ratings.count == CONSECUTIVE_BAD_RATINGS_COUNT && recent_ratings.all?(Discussion::RATING_BAD)
  end

  def reset_consecutive_bad_ratings!
    update(consecutive_bad_ratings_at: nil) if consecutive_bad_ratings_at
  end

  def best_antifeatures_for_locale(locale)
    antifeatures.group_by(&:antifeature_type).values.map do |afs|
      afs.find { |af| af.locale == locale } || afs.find { |af| af.locale.nil? } || afs.first
    end
  end

  def host
    return Rails.application.routes.default_url_options[:host] unless sensitive?

    return Rails.env.production? ? 'sleazyfork.org' : 'sleazyfork.local'
  end

  def similar_scripts(script_subset:, locale:)
    return @_similar_scripts unless @_similar_scripts.nil?

    sas = site_applications.domain.pluck(:id)
    return Script.none if sas.none?

    locale = Locale.find_by(code: locale) if locale.is_a?(String) || locale.is_a?(Symbol)

    with = {
      script_type: Script.script_types[:public],
      site_application_id: sas,
      locale: locale.id,
    }

    case script_subset
    when :greasyfork
      with[:sensitive] = false
    when :sleazyfork
      with[:sensitive] = true
    end

    @_similiar_scripts = Script
                         .search(
                           '*',
                           where: with,
                           includes: [:localized_attributes, :users],
                           order: { daily_installs: :desc },
                           per_page: 25
                         )
                         .reject { |script| script.id == id }
                         .sort_by { |script| [(script.users & users).any? ? 0 : 1, script.daily_installs * -1] }
                         .first(5)

    @_similiar_scripts.select!(&:adsense_approved) if adsense_approved

    @_similiar_scripts
  end

  def bad_integrity_hashes
    subresource_usages_with_hashes = subresource_usages.where.not(integrity_hash: nil).load
    return [] unless subresource_usages_with_hashes.any?

    sris = subresource_usages_with_hashes.filter_map do |subresource_usage|
      SubresourceIntegrityHash.where(subresource_id: subresource_usage.subresource_id, algorithm: subresource_usage.algorithm, encoding: subresource_usage.encoding).where.not(integrity_hash: subresource_usage.integrity_hash).first
    end

    sris.map { |sri| { url: sri.subresource.url, expected_hash: "#{sri.algorithm}=#{sri.integrity_hash}", last_success_at: sri.subresource.last_success_at } }
  end

  def unlock!
    self.delete_type = nil
    self.replaced_by_script_id = nil
    self.delete_reason = nil
    self.delete_report = nil
    self.permanent_deletion_request_date = nil
    self.locked = false
    save!
  end

  private

  def url_helpers
    Rails.application.routes.url_helpers
  end

  def update_localized_attribute(meta_keys, attr_name)
    default_value = meta_keys.key?(attr_name) ? meta_keys[attr_name].first : nil
    # for libraries, if there's no default, just leave as is
    return if library? && default_value.nil?

    existing_localized_attributes = localized_attributes_for(attr_name)

    unless default_value.nil?
      default_la = existing_localized_attributes.find { |la| la.locale_id == locale&.id && la.attribute_key == attr_name && la.attribute_default }
      if default_la.nil?
        default_la = localized_attributes.build({ attribute_key: attr_name, attribute_default: true, locale: })
      else
        existing_localized_attributes.delete(default_la)
      end
      default_la.assign_attributes({ attribute_value: default_value, value_markup: 'text' })
    end

    meta_keys.select { |n, _v| n.starts_with?("#{attr_name}:") }.each do |n, v|
      locale_code = n.split(':', 2).last
      meta_locale = Locale.find_by(code: locale_code)
      if meta_locale.nil?
        Rails.logger.error "Unknown locale code - #{locale_code}"
        next
      end

      # Ignore if we match the default locale
      next if meta_locale == locale

      matching_la = existing_localized_attributes.find { |la| la.locale == meta_locale && la.attribute_key == attr_name }
      if matching_la.nil?
        matching_la = localized_attributes.build({ attribute_key: attr_name, locale: meta_locale })
      else
        existing_localized_attributes.delete(matching_la)
      end
      matching_la.assign_attributes({ attribute_value: v.first, attribute_default: false, value_markup: 'text' })
    end

    existing_localized_attributes.each(&:mark_for_destruction)
  end

  def update_children(child_name, new_data)
    existing_children = send(child_name).to_a
    new_data.each do |new_hash|
      # See if a record like that already exists.
      matching_existing = existing_children.find do |child|
        new_hash.keys.all? { |k| new_hash[k] == child.send(k) }
      end
      # Leave it alone, remove it from the search array, and move on
      unless matching_existing.nil?
        existing_children.delete(matching_existing)
        next
      end
      # Make a new one
      # Specify script again - https://github.com/rails/rails/issues/26817
      send(child_name).build(new_hash.merge(script: self))
    end
    # Anything left in the search array, mark for destruction
    existing_children.each(&:mark_for_destruction)
  end

  def clear_latest_cached_code
    %w[greasyfork sleazyfork].each do |site_name|
      Dir.glob(Rails.application.config.cached_code_path.join(site_name, 'latest', 'scripts', "#{id}.*")).each do |path|
        File.delete(path)
      rescue Errno::ENOENT
        # Already gone
      end
    end
  end
end
