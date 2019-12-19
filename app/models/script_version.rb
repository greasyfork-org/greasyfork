require 'uri'
require 'localizing_model'
require 'js_checker'
require 'js_parser'
require 'css_parser'

class ScriptVersion < ApplicationRecord
  self.ignored_columns = %w(approve_redistribution)

  include LocalizingModel
  include ScriptVersionJs

  # This needs to be before_save to run before the autosave callbacks.
  # It will actually only do anything when new_record?.
  before_save :reuse_script_codes

  belongs_to :script
  belongs_to :script_code, :autosave => true
  belongs_to :rewritten_script_code, :class_name => 'ScriptCode', :autosave => true

  has_many :localized_attributes, class_name: 'LocalizedScriptVersionAttribute', autosave: true, dependent: :destroy
  has_and_belongs_to_many :screenshots, autosave: true, dependent: :destroy

  delegate :js?, :css?, to: :script

  strip_attributes :only => [:changelog]

  validates_presence_of :code

  validates_length_of :code, :maximum => 2000000
  validates_length_of :changelog, :maximum => 500

  validate :number_of_screenshots
  def number_of_screenshots
    errors.add(:base, I18n.t('errors.messages.script_too_many_screenshots', :number => Rails.configuration.screenshot_max_count)) if screenshots.length > Rails.configuration.screenshot_max_count
  end

  attr_accessor :unauthorized_original
  validates_each(:code, :allow_nil => true, :allow_blank => true) do |record, attr, value|
    meta = record.parser_class.parse_meta(value)

    ScriptVersion.disallowed_codes_used_for_code(value).each do |dc|
      if value =~ Regexp.new(dc.pattern)
        if dc.originating_script
          # Possibly not saved - can't do record.users
          if (record.script.authors.map(&:user) & dc.originating_script.users).none?
            record.unauthorized_original = dc.originating_script
            record.errors.add(:base, "appears to be an unauthorized copy")
          end
        else
          record.errors.add(:base, "Exception #{dc.ob_code}")
        end
      end
    end
  end

  # Warnings are separated because we need to show custom UI for them (including checkboxes to override)
  validate do |record|
    record.warnings.each {|w| record.errors.add(:base, "warning-" + w.to_s)}
  end

  validates_each :localized_attributes do |s, attr, children|
    s.errors[attr].clear
    children.each do |child|
      child.errors.keys.each{|key| s.errors[attr.to_s + '.' + key.to_s].clear}
      next if child.marked_for_destruction? or child.valid?
      child.errors.each do |child_attr, msg|
        s.errors[:base] << I18n.t("activerecord.attributes.script." + child.attribute_key) + " - " + I18n.t("activerecord.attributes.script." + child_attr.to_s, :default => child_attr.to_s) + " " + msg
      end
    end
  end

  # Multiple additional infos in the same locale
  validate do |record|
    # The default will get set to the script's locale
    additional_info_locales = localized_attributes_for('additional_info').map{|la|(la.locale.nil? && la.attribute_default) ? script.locale : la.locale}.select{|l| !l.nil?}
    duplicated_locales = additional_info_locales.select{|l| additional_info_locales.count(l) > 1 }.uniq
    duplicated_locales.each {|l| record.errors[:base] << I18n.t("scripts.additional_info_locale_repeated", {:locale_code => l.code})}
  end

  # Additional info where no @name for that locale exists. This is OK if the script locale matches, though.
  validate do |record|
    additional_info_locales = localized_attributes_for('additional_info').select{|la|!la.attribute_default}.map{|la|la.locale.nil? ? script.locale : la.locale}.select{|l| !l.nil?}.uniq
    meta_keys = record.parser_class.parse_meta(code)
    additional_info_locales.each{|l|
      record.errors[:base] << I18n.t('scripts.localized_additional_info_with_no_name', {:locale_code => l.code}) if !meta_keys.include?('name:' + l.code) and l != script.locale
    }
  end

  before_validation :set_locale
  before_save :set_locale
  def set_locale
    localized_attributes.select{|la| la.locale.nil?}.each{|la| la.locale = script.locale}
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
    return w
  end

  def version_missing?
    return false if add_missing_version

    # exempt scripts that are (being) deleted as well as libraries
    return false if !script.nil? and (script.deleted? or script.library?)

    return version.nil?
  end

  # Version should be incremented when code changes
  def version_not_incremented?
    return false if version_check_override
    return false if version.nil?

    # exempt scripts that are (being) deleted as well as libraries
    return false if !script.nil? and (script.deleted? or script.library?)

    # did the code change?
    previous_script_version = script.get_newest_saved_script_version
    return false if previous_script_version.nil?
    return false if code == previous_script_version.code

    return ScriptVersion.compare_versions(version, previous_script_version.version) != 1
  end

  # namespace is required
  def namespace_missing?
    return false if add_missing_namespace
    # exempt scripts that are (being) deleted as well as libraries
    return false if !script.nil? and (script.deleted? or script.library?)

    # previous namespace will be used in calculate_rewritten_code if this one doesn't have one
    previous_namespace = get_meta_from_previous('namespace', true)
    return false if !previous_namespace.nil? and !previous_namespace.empty?

    meta = parser_class.parse_meta(code)
    # handled elsewhere
    return false if meta.nil?

    return !meta.has_key?('namespace')
  end

  # namespace shouldn't change
  def namespace_changed?
    return false if namespace_check_override
    # exempt scripts that are (being) deleted as well as libraries
    return false if !script.nil? and (script.deleted? or script.library?)

    meta = parser_class.parse_meta(code)
    # handled elsewhere
    return false if meta.nil?

    # handled in namespace_missing?
    namespaces = meta['namespace']
    return false if namespaces.nil? or namespaces.empty?

    namespace = namespaces.first

    previous_namespace = get_meta_from_previous('namespace', true)
    previous_namespace = (previous_namespace.nil? or previous_namespace.empty?) ? nil : previous_namespace.first

    # if there was no previous namespace, then anything new is fine
    return false if previous_namespace.nil?

    return namespace != previous_namespace
  end

  # things shouldn't be minified
  def potentially_minified?
    return false if minified_confirmation or !disallowed_codes_used.empty?
    # only warn on new
    return false if script.nil? or !script.new_record?
    return ScriptVersion.code_appears_minified(code)
  end

  def automatic_sensitive?
    return false if sensitive_site_confirmation
    return false if script.sensitive
    return false if script.adult_content_self_report
    return sensitive_domains.any?
  end

  def sensitive_domains
    domain_names = calculate_applies_to_names.select{|atn| atn[:domain] && !atn[:tld_extra]}.map{|atn| atn[:text]}
    return SensitiveSite.where(domain: domain_names).map(&:domain)
  end

  attr_accessor :version_check_override, :add_missing_version, :namespace_check_override, :add_missing_namespace, :minified_confirmation, :truncate_description, :sensitive_site_confirmation

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
    super(*args)
  end

  # reuse script code objects to save disk space
  def reuse_script_codes
    return if !new_record?

    code_found = false
    rewritten_code_found = false

    # check if one of the previous versions had the same code, reuse if so
    if !self.script.nil?
      self.script.script_versions.each do |old_sv|
        # only use older versions for this
        break if !self.id.nil? and self.id < old_sv.id
        next if old_sv == self
        if !code_found
          if old_sv.code == self.code
            self.script_code = old_sv.script_code
            code_found = true
          elsif old_sv.rewritten_code == self.code
            self.script_code = old_sv.rewritten_script_code
            code_found = true
          end
        end
        if !rewritten_code_found
          if old_sv.rewritten_code == self.rewritten_code
            self.rewritten_script_code = old_sv.rewritten_script_code
            rewritten_code_found = true
          elsif old_sv.code == self.rewritten_code
            self.rewritten_script_code = old_sv.script_code
            rewritten_code_found = true
          end
        end
        break if code_found and rewritten_code_found
      end
    end

    # if we didn't find a previous version, see if original and rewritten are the same in the current version
    if !code_found and self.rewritten_code == self.code
      self.script_code = self.rewritten_script_code
    elsif !rewritten_code_found and self.rewritten_code == self.code
      self.rewritten_script_code = self.script_code
    end

  end

  def code
    script_code.nil? ? nil : script_code.code
  end

  def code=(c)
    # no op if the same
    return if self.code == c
    #self.script_code = ScriptCode.new
    self.build_script_code
    self.script_code.code = c
  end

  def rewritten_code
    rewritten_script_code.nil? ? nil : rewritten_script_code.code
  end

  def rewritten_code=(c)
    # no op if the same
    return if self.rewritten_code == c
    #self.rewritten_script_code = ScriptCode.new
    self.build_rewritten_script_code
    self.rewritten_script_code.code = c
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
  end

  def calculate_all(previous_description = nil)
    normalize_code
    meta = parser_class.parse_meta(code)
    if meta.has_key?('version')
      self.version = meta['version'].first
    else
      nssv = script.get_newest_saved_script_version
      if !nssv.nil? and nssv.code == code
        # no update, use the last one
        self.version = nssv.version
        # generate the version ourselves if the user asked or if the previous one was generated
      elsif self.add_missing_version or (!nssv.nil? and /^0\.0\.1\.[0-9]{14}$/ =~ nssv.version)
        # a "low" version based on timestamp so if the author decides to start using versions, they'll beat ours
        self.version = "0.0.1.#{Time.now.utc.strftime('%Y%m%d%H%M%S')}"
      else
        self.version = nil
      end
    end
    self.rewritten_code = calculate_rewritten_code(previous_description)
  end

  def get_rewritten_meta_block
    parser_class.get_meta_block(rewritten_code)
  end

  def get_blanked_code
    ScriptVersion.get_blanked_code(rewritten_code)
  end

  def self.get_blanked_code(rewritten_code)
    c = JsParser.get_meta_block(rewritten_code)
    return nil if c.nil?
    current_version = ScriptVersion.get_first_meta(c, 'version')
    return JsParser.inject_meta(c, { description: 'This script was deleted from Greasy Fork, and due to its negative effects, it has been automatically removed from your browser.', version: ScriptVersion.get_next_version(current_version), :require => nil, icon: nil, resource: nil})
  end

  def calculate_rewritten_code(previous_description = nil)
    return code if !script.nil? and script.library?
    add_if_missing = {}
    backup_namespace = calculate_backup_namespace
    add_if_missing[:namespace] = backup_namespace if !backup_namespace.nil?
    add_if_missing[:description] = previous_description if !previous_description.nil?
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
    previous_namespace = get_meta_from_previous('namespace', true)
    return previous_namespace.first unless previous_namespace.nil? or previous_namespace.empty?
    return nil if !add_missing_namespace
    return Rails.application.routes.url_helpers.user_url(:id => script.authors.first.user_id)
  end

  def calculate_applies_to_names
    parser_class.calculate_applies_to_names(code)
  end

  def normalize_code
    self.code = '' if code.nil?
    # use \n for linefeeds
    self.code = code.gsub("\r\n", "\n").gsub("\r", "\n")
  end

  def disallowed_requires_used
    r = []
    meta = parser_class.parse_meta(code)
    return r if !meta.has_key?('require')
    allowed_requires = AllowedRequire.all
    meta['require'].each do |script_url|
      r << script_url if allowed_requires.none?{ |ar| script_url =~ Regexp.new(ar.pattern) }
    end
    return r
  end

  def disallowed_codes_used
    return self.class.disallowed_codes_used_for_code(self.code)
  end

  def self.disallowed_codes_used_for_code(c)
    return DisallowedCode.where(slow_ban: false).select { |dc| c =~ Regexp.new(dc.pattern)}
  end

  def self.compare_versions(v1, v2)
    # Differences between our compare and Ruby's
    # - ours: "A string-part that exists is always less than a string-part that doesn't exist (1.6a is less than 1.6)."
    # - Ruby: "If the strings are of different lengths, and the strings are equal when compared up to the shortest length, then the longer string is considered greater than the shorter one."
    sv1 = ScriptVersion.split_version(v1)
    sv2 = ScriptVersion.split_version(v2)
    return nil if sv1.nil? or sv2.nil?
    (0..15).each do |i|
      # Odds are strings
      if i.odd?
        return 1 if sv1[i].empty? and !sv2[i].empty?
        return -1 if !sv1[i].empty? and sv2[i].empty?
      end
      r = sv1[i] <=> sv2[i]
      return r if r != 0
    end
    return 0
  end

  def get_meta_from_previous(key, use_rewritten = false)
    return nil if script.nil?
    previous_script_version = script.get_newest_saved_script_version
    return nil if previous_script_version.nil?
    previous_meta = parser_class.parse_meta(use_rewritten ? previous_script_version.rewritten_code : previous_script_version.code)
    return nil if previous_meta.nil?
    return previous_meta[key]
  end

  # Returns the first meta value matching the passed code, or nil
  def self.get_first_meta(c, meta_name)
    meta = JsParser.parse_meta(c)
    return meta[meta_name].first if meta.has_key?(meta_name)
    return nil
  end

  # Increments the passed version
  def self.get_next_version(v)
    a = split_version(v)
    # wipe out zeros
    [0, 2, 4, 6, 8, 10, 12, 14].each do |i|
      a[i] = nil if a[i] == 0
    end
    # incremement the last numeric value - position 12 if 13 and 14 aren't set, 14 if either is
    if a[13].empty? and a[14].nil?
      a[12] = a[12].nil? ? 1 : a[12] + 1
    else
      a[14] = a[14].nil? ? 1 : a[14] + 1
    end
    p1 = a[0..3].join('')
    p2 = a[4..7].join('')
    p3 = a[8..11].join('')
    p4 = a[12..15].join('')
    return [p1, p2, p3, p4].map{|p| p.empty? ? '0' : p}.join('.')
  end

  def appears_minified
    ScriptVersion.code_appears_minified(code)
  end

  def self.code_appears_minified(value)
    return value.split("\n").any? {|s| s.length > 5000 and s.include?('function') }
  end

  def additional_info
    return default_localized_value_for('additional_info')
  end

  def additional_info_markup
    la = localized_attributes_for('additional_info').select{|la| la.attribute_default}.first
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

  private

  # Returns a 16 element array of version info per https://developer.mozilla.org/en-US/docs/Toolkit_version_format
  def self.split_version(v)
    # up to 4 strings separated by dots
    a = v.split('.', 4)
    # missing part counts as 0
    until a.length == 4
      a << '0'
    end
    return a.map { |p|
      # each part consists of number, string, number, string, each part optional
      # string #2 we will assume is no numbers, string #4 will eat whatever's left
      match_array = /((?:\-?[0-9]+)?)([^0-9\-]*)((?:\-?[0-9]+)?)(.*)/.match(p)
      [match_array[1].to_i, match_array[2], match_array[3].to_i, match_array[4]]
    }.flatten
  end
end
