require 'uri'
require 'localizing_model'
require 'js_checker'
require 'js_parser'
require 'css_parser'

class ScriptVersion < ApplicationRecord
  include LocalizingModel
  include ScriptVersionJs
  include HasAttachments

  before_validation :set_locale
  # This needs to be before_save to run before the autosave callbacks.
  # It will actually only do anything when new_record?.
  before_save :reuse_script_codes

  belongs_to :script
  belongs_to :script_code, autosave: true
  belongs_to :rewritten_script_code, class_name: 'ScriptCode', autosave: true

  has_many :localized_attributes, class_name: 'LocalizedScriptVersionAttribute', autosave: true, dependent: :destroy

  delegate :js?, :css?, to: :script

  strip_attributes only: [:changelog]

  ThinkingSphinx::Callbacks.append(self, :script, behaviours: [:sql, :deltas], path: [:script])

  validates :code, presence: true, length: { minimum: 20, maximum: 2_000_000 }, on: :create

  # Code has to look code-y.
  validate on: :create do
    errors.add(:code, :invalid) unless /[=.:\[(]/.match?(code)
  end

  validate :number_of_attachments, on: :create
  def number_of_attachments
    errors.add(:base, I18n.t('errors.messages.script_too_many_screenshots', number: Rails.configuration.screenshot_max_count)) if attachments.count > Rails.configuration.screenshot_max_count
  end

  # Warnings are separated because we need to show custom UI for them (including checkboxes to override)
  validate on: :create do |record|
    record.warnings.each { |w| record.errors.add(:base, "warning-#{w}") }
  end

  validates_each :localized_attributes, on: :create do |s, attr, children|
    s.errors.delete(attr)
    children.each do |child|
      child.errors.attribute_names.each { |key| s.errors.delete("#{attr}.#{key}") }
      next if child.marked_for_destruction? || child.valid?

      child.errors.each do |error|
        s.errors.add(:base, error.type, message: "#{I18n.t("activerecord.attributes.script.#{child.attribute_key}")} - #{I18n.t("activerecord.attributes.script.#{error.attribute}", default: error.type.to_s)} #{error.message}")
      end
    end
  end

  # Multiple additional infos in the same locale
  validate on: :create do |record|
    # The default will get set to the script's locale
    additional_info_locales = localized_attributes_for('additional_info').map { |la| (la.locale.nil? && la.attribute_default) ? script.locale : la.locale }.reject(&:nil?)
    duplicated_locales = additional_info_locales.select { |l| additional_info_locales.count(l) > 1 }.uniq
    duplicated_locales.each { |l| record.errors.add(:base, :additional_info_locale_repeated, message: I18n.t('scripts.additional_info_locale_repeated', locale_code: l.code)) }
  end

  # Additional info where no @name for that locale exists. This is OK if the script locale matches, though.
  validate on: :create do |record|
    additional_info_locales = localized_attributes_for('additional_info').reject(&:attribute_default).map { |la| la.locale.nil? ? script.locale : la.locale }.reject(&:nil?).uniq
    meta_keys = record.parser_class.parse_meta(code)
    additional_info_locales.each do |l|
      record.errors.add(:base, :localized_additional_info_with_no_name, message: I18n.t('scripts.localized_additional_info_with_no_name', locale_code: l.code)) if meta_keys.exclude?("name:#{l.code}") && (l != script.locale)
    end
  end

  # Additional info where no @name for that locale exists. This is OK if the script locale matches, though.
  validate on: :create do |record|
    next unless record.script.locale

    meta = parser_class.parse_meta(record.code)
    record.errors.add(:base, :localized_name_matches_default_locale, message: I18n.t('scripts.localized_attribute_matches_default', meta_key: "@name:#{record.script.locale.code}", locale_code: record.script.locale.code)) if meta["name:#{record.script.locale.code}"]
    record.errors.add(:base, :localized_description_matches_default_locale, message: I18n.t('scripts.localized_attribute_matches_default', meta_key: "@description:#{record.script.locale.code}", locale_code: record.script.locale.code)) if meta["description:#{record.script.locale.code}"]
  end

  validate on: :create do |record|
    next if record.script.library? || !record.js?

    meta = record.meta
    record.errors.add(:code, :missing_include_or_match) if !meta.key?('include') && !meta.key?('match')
  end

  before_save :set_locale
  def set_locale
    localized_attributes.select { |la| la.locale.nil? }.each { |la| la.locale = script.locale }
  end

  after_create do
    script.reset_consecutive_bad_ratings!
  end

  # Delete the code if not in use by another version.
  after_destroy do
    script_code.destroy! if script_code.present? && ScriptVersion.where(['script_code_id = ? or rewritten_script_code_id = ?', script_code_id, script_code_id]).where.not(id: id).none?
    rewritten_script_code.destroy! if rewritten_script_code.present? && ScriptVersion.where(['script_code_id = ? or rewritten_script_code_id = ?', rewritten_script_code_id, rewritten_script_code_id]).where.not(id: id).none?
  end

  def warnings
    w = []
    w << :version_missing if version_missing?
    w << :version_not_incremented if version_not_incremented?
    w << :namespace_missing if namespace_missing?
    w << :namespace_changed if namespace_changed?
    w << :potentially_minified if potentially_minified?
    w << :automatic_sensitive if automatic_sensitive?
    w << :code_previously_posted if code_previously_posted?
    return w
  end

  def version_missing?
    return false if add_missing_version

    # exempt scripts that are (being) deleted as well as libraries
    return false if !script.nil? && (script.deleted? || script.library?)

    return version.nil?
  end

  # Version should be incremented when code changes
  def version_not_incremented?
    return false if version_check_override
    return false if version.nil?

    # exempt scripts that are (being) deleted as well as libraries
    return false if !script.nil? && (script.deleted? || script.library?)

    # did the code change?
    previous_script_version = script.newest_saved_script_version
    return false if previous_script_version.nil?
    return false if code == previous_script_version.code

    return ScriptVersion.compare_versions(version, previous_script_version.version) != 1
  end

  # namespace is required
  def namespace_missing?
    return false if add_missing_namespace
    # exempt scripts that are (being) deleted as well as libraries
    return false if !script.nil? && (script.deleted? || script.library?)

    # previous namespace will be used in calculate_rewritten_code if this one doesn't have one
    previous_namespace = get_meta_from_previous('namespace', use_rewritten: true)
    return false if previous_namespace.present?

    meta = parser_class.parse_meta(code)
    # handled elsewhere
    return false if meta.nil?

    return !meta.key?('namespace')
  end

  # namespace shouldn't change
  def namespace_changed?
    return false if namespace_check_override
    # exempt scripts that are (being) deleted as well as libraries
    return false if !script.nil? && (script.deleted? || script.library?)

    meta = parser_class.parse_meta(code)
    # handled elsewhere
    return false if meta.nil?

    # handled in namespace_missing?
    namespaces = meta['namespace']
    return false if namespaces.blank?

    namespace = namespaces.first

    previous_namespace = get_meta_from_previous('namespace', use_rewritten: true)
    previous_namespace = previous_namespace.blank? ? nil : previous_namespace.first

    # if there was no previous namespace, then anything new is fine
    return false if previous_namespace.nil?

    return namespace != previous_namespace
  end

  # things shouldn't be minified
  def potentially_minified?
    return false if minified_confirmation
    # only warn on new
    return false if script.nil? || !script.new_record?

    return ScriptVersion.code_appears_minified(code)
  end

  def automatic_sensitive?
    return false if sensitive_site_confirmation
    return false if script.sensitive_was
    return false if script.adult_content_self_report

    return sensitive_domains.any?
  end

  def sensitive_domains
    domain_names = calculate_applies_to_names.select { |atn| atn[:domain] && !atn[:tld_extra] }.pluck(:text)
    return SensitiveSite.where(domain: domain_names).map(&:domain)
  end

  def code_previously_posted?
    return false if allow_code_previously_posted || !new_record?

    hash = script_code.calculate_hash
    previously_posted_scope = ScriptVersion.joins(:script).merge(Script.not_deleted).where.not(script_id: script_id)
    # Split into two queries to better use the indexes.
    self.previously_posted_scripts = (
          previously_posted_scope.joins(:script_code).where(script_codes: { code_hash: hash }) +
          previously_posted_scope.joins(:rewritten_script_code).where(script_codes: { code_hash: hash })
        ).map(&:script).uniq
    previously_posted_scripts.any?
  end

  attr_accessor :version_check_override, :add_missing_version, :namespace_check_override, :add_missing_namespace,
                :minified_confirmation, :truncate_description, :sensitive_site_confirmation,
                :allow_code_previously_posted, :previously_posted_scripts

  def initialize(*args)
    # Allow code to be updated without version being upped
    @version_check_override = false
    # Set a version by ourselves if not provided
    @add_missing_version = false
    # Allow the namespace to change
    @namespace_check_override = false
    # Set a namespace by ourselves if not provided
    @add_missing_namespace = false
    # Minified warning override
    @minified_confirmation = false
    # Truncate description if it's too long
    @truncate_description = false
    # Confirm automatic adult detection
    @sensitive_site_confirmation = false
    # Allow code that was already posted elsewhere
    @allow_code_previously_posted = false
    @previously_posted_scripts = []
    super(*args)
  end

  # reuse script code objects to save disk space
  def reuse_script_codes
    return unless new_record?

    code_found = false
    rewritten_code_found = false

    # check if one of the previous versions had the same code, reuse if so
    # only use older versions for this
    script&.script_versions&.each do |old_sv|
      # only use older versions for this
      break if !id.nil? && (id < old_sv.id)
      next if old_sv == self

      unless code_found
        if old_sv.code == code
          self.script_code = old_sv.script_code
          code_found = true
        elsif old_sv.rewritten_code == code
          self.script_code = old_sv.rewritten_script_code
          code_found = true
        end
      end
      unless rewritten_code_found
        if old_sv.rewritten_code == rewritten_code
          self.rewritten_script_code = old_sv.rewritten_script_code
          rewritten_code_found = true
        elsif old_sv.code == rewritten_code
          self.rewritten_script_code = old_sv.script_code
          rewritten_code_found = true
        end
      end
      break if code_found && rewritten_code_found
    end

    # if we didn't find a previous version, see if original and rewritten are the same in the current version
    if !code_found && (rewritten_code == code)
      self.script_code = rewritten_script_code
    elsif !rewritten_code_found && (rewritten_code == code)
      self.rewritten_script_code = script_code
    end
  end

  def code
    script_code.nil? ? nil : script_code.code
  end

  def code=(new_code)
    # no op if the same
    return if code == new_code

    # self.script_code = ScriptCode.new
    build_script_code
    script_code.code = new_code
  end

  def rewritten_code
    rewritten_script_code.nil? ? nil : rewritten_script_code.code
  end

  def rewritten_code=(new_code)
    # no op if the same
    return if rewritten_code == new_code

    # self.rewritten_script_code = ScriptCode.new
    build_rewritten_script_code
    rewritten_script_code.code = new_code
  end

  # Try our best to accept the code
  def do_lenient_saving
    @version_check_override = true
    @add_missing_version = true
    @add_missing_namespace = true
    @namespace_check_override = true
    @minified_confirmation = true
    @truncate_description = true
    @sensitive_site_confirmation = true
    @allow_code_previously_posted = true
  end

  def calculate_all(previous_description = nil)
    normalize_code
    meta = parser_class.parse_meta(code)
    if meta.key?('version')
      self.version = meta['version'].first
    else
      nssv = script.newest_saved_script_version
      self.version = if !nssv.nil? && (nssv.code == code)
                       # no update, use the last one
                       nssv.version
                     # generate the version ourselves if the user asked or if the previous one was generated
                     elsif add_missing_version || (!nssv.nil? && /^0\.0\.1\.[0-9]{14}$/ =~ nssv.version)
                       # a "low" version based on timestamp so if the author decides to start using versions, they'll beat ours
                       "0.0.1.#{Time.now.utc.strftime('%Y%m%d%H%M%S')}"
                     end
    end
    self.rewritten_code = calculate_rewritten_code(previous_description)
  end

  def generate_rewritten_meta_block
    parser_class.get_meta_block(rewritten_code)
  end

  def generate_blanked_code
    ScriptVersion.generate_blanked_code(rewritten_code)
  end

  def self.generate_blanked_code(rewritten_code, parser = JsParser)
    c = parser.get_meta_block(rewritten_code)
    return nil if c.nil?

    current_version = ScriptVersion.get_first_meta(c, 'version') || '0.1'
    return parser.inject_meta(c, { description: 'This script was deleted from Greasy Fork, and due to its negative effects, it has been automatically removed from your browser.', version: ScriptVersion.get_next_version(current_version), require: nil, icon: nil, resource: nil })
  end

  def calculate_rewritten_code(previous_description = nil)
    return code if !script.nil? && script.library?

    add_if_missing = {}
    backup_namespace = calculate_backup_namespace
    add_if_missing[:namespace] = backup_namespace unless backup_namespace.nil?
    add_if_missing[:description] = previous_description unless previous_description.nil?
    rewritten_meta = parser_class.inject_meta(code, {
                                                version: version,
                                                updateURL: nil,
                                                installURL: nil,
                                                downloadURL: nil,
                                              }, add_if_missing)
    return nil if rewritten_meta.nil?

    return rewritten_meta
  end

  # returns a potential namespace to use if one is not set
  def calculate_backup_namespace
    # use the rewritten code as the previous one may have been a backup as well
    previous_namespace = get_meta_from_previous('namespace', use_rewritten: true)
    return previous_namespace.first if previous_namespace.present?
    return nil unless add_missing_namespace

    return Rails.application.routes.url_helpers.user_url(id: script.authors.first.user_id)
  end

  def calculate_applies_to_names
    parser_class.calculate_applies_to_names(code)
  end

  def normalize_code
    self.code = '' if code.nil?
    # use \n for linefeeds
    self.code = code.gsub("\r\n", "\n").tr("\r", "\n")
  end

  def disallowed_requires_used
    r = []
    meta = parser_class.parse_meta(code)
    return r unless meta.key?('require')

    allowed_requires = AllowedRequire.all
    meta['require'].each do |script_url|
      r << script_url if allowed_requires.none? { |ar| script_url =~ Regexp.new(ar.pattern) }
    end
    return r
  end

  def self.compare_versions(v1, v2)
    # Differences between our compare and Ruby's
    # - ours: "A string-part that exists is always less than a string-part that doesn't exist (1.6a is less than 1.6)."
    # - Ruby: "If the strings are of different lengths, and the strings are equal when compared up to the shortest length, then the longer string is considered greater than the shorter one."
    sv1 = ScriptVersion.split_version(v1)
    sv2 = ScriptVersion.split_version(v2)
    return nil if sv1.nil? || sv2.nil?

    (0..15).each do |i|
      # Odds are strings
      if i.odd?
        return 1 if sv1[i].empty? && !sv2[i].empty?
        return -1 if !sv1[i].empty? && sv2[i].empty?
      end
      r = sv1[i] <=> sv2[i]
      return r if r != 0
    end
    return 0
  end

  def get_meta_from_previous(key, use_rewritten: false)
    return nil if script.nil?

    previous_script_version = script.newest_saved_script_version
    return nil if previous_script_version.nil?

    previous_meta = parser_class.parse_meta(use_rewritten ? previous_script_version.rewritten_code : previous_script_version.code)
    return nil if previous_meta.nil?

    return previous_meta[key]
  end

  # Returns the first meta value matching the passed code, or nil
  def self.get_first_meta(code, meta_name)
    meta = JsParser.parse_meta(code)
    return meta[meta_name].first if meta.key?(meta_name)

    return nil
  end

  # Increments the passed version
  def self.get_next_version(version_number)
    a = split_version(version_number)
    # wipe out zeros
    [0, 2, 4, 6, 8, 10, 12, 14].each do |i|
      a[i] = nil if a[i] == 0
    end
    # incremement the last numeric value - position 12 if 13 and 14 aren't set, 14 if either is
    if a[13].empty? && a[14].nil?
      a[12] = a[12].nil? ? 1 : a[12] + 1
    else
      a[14] = a[14].nil? ? 1 : a[14] + 1
    end
    p1 = a[0..3].join
    p2 = a[4..7].join
    p3 = a[8..11].join
    p4 = a[12..15].join
    return [p1, p2, p3, p4].map { |p| p.empty? ? '0' : p }.join('.')
  end

  def self.code_appears_minified(value)
    return value.split("\n").any? { |s| (s.length > 5000) && s.include?('function') }
  end

  def meta
    parser_class.parse_meta(code)
  end

  def additional_info
    return default_localized_value_for('additional_info')
  end

  def additional_info_markup
    la = localized_attributes_for('additional_info').find(&:attribute_default)
    return 'html' if la.nil?

    return la.value_markup
  end

  def parser_class
    case script.language
    when 'js'
      JsParser
    when 'css'
      CssParser
    else
      raise 'Unknown language'
    end
  end

  def script_versions_with_identical_code
    script_code_ids = ScriptCode.where(code_hash: [script_code.code_hash, rewritten_script_code.code_hash].uniq).pluck(:id)
    ScriptVersion
      .joins(:script)
      .merge(Script.not_deleted)
      .where.not(script_id: script_id)
      .where(['script_code_id IN (?) OR rewritten_script_code_id IN (?)', script_code_ids, script_code_ids])
  end

  # Returns a 16 element array of version info per https://developer.mozilla.org/en-US/docs/Toolkit_version_format
  def self.split_version(version_number)
    # up to 4 strings separated by dots
    a = version_number.split('.', 4)
    # missing part counts as 0
    a << '0' until a.length == 4
    return a.map do |p|
      # each part consists of number, string, number, string, each part optional
      # string #2 we will assume is no numbers, string #4 will eat whatever's left
      match_array = /((?:-?[0-9]+)?)([^0-9\-]*)((?:-?[0-9]+)?)(.*)/.match(p)
      [match_array[1].to_i, match_array[2], match_array[3].to_i, match_array[4]]
    end.flatten
  end
end
