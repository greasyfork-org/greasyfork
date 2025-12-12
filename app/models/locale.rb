require 'memo_wise'

class Locale < ApplicationRecord
  prepend MemoWise

  @locale_cache = {}

  has_many :scripts, dependent: :restrict_with_exception
  has_many :locale_contributors, dependent: :destroy

  scope :with_listable_scripts, ->(script_subset) { joins(:scripts).where(scripts: Script.listable(script_subset).where_values_hash).distinct.order(:code) }

  def self.english
    fetch_locale('en')
  end

  def self.simplified_chinese
    fetch_locale('zh-CN')
  end

  def display_text(in_locale: I18n.locale)
    "#{best_name(in_locale:)} (#{code})"
  end

  def best_name(in_locale:)
    in_locale = in_locale.code if in_locale.is_a?(Locale)
    # The data from the gem does not have region-specific names.
    in_locale = in_locale.to_s.split('-').first

    language_code, country_code = code.split('-', 2)
    language_name_in_current_language, country_name_in_current_language = nil

    begin
      language_name_in_current_language = I18nData.languages(in_locale)[language_code.upcase]&.split(';')&.first
      country_name_in_current_language = I18nData.countries(in_locale)[country_code] if country_code
    rescue I18nData::NoTranslationAvailable
      # in_locale is not supported by I18nData.
    end

    if country_code
      return "#{language_name_in_current_language} (#{country_name_in_current_language})" if language_name_in_current_language && country_name_in_current_language
    elsif language_name_in_current_language
      return language_name_in_current_language
    end

    native_name || english_name
  end
  memo_wise :best_name

  # Returns the matching locales for the passed locale code, with locales with UI available first.
  def self.matching_locales(locale_code, chinese_only: false)
    locale_codes_to_look_up = [locale_code]
    if locale_code.include?('-')
      language_part_only = locale_code.split('-').first
      locale_codes_to_look_up << language_part_only if language_part_only
    else
      language_part_only = locale_code
    end

    locale_scope = all
    locale_scope = locale_scope.where("code LIKE 'zh%'") if chinese_only

    # The dashed one is last alphabetically but first in our hearts.
    locales = locale_scope.where(code: locale_codes_to_look_up).order(ui_available: :asc, code: :desc).load
    return locales if locales.any?

    # Special case for Chinese locales that are more similar to zh-TW than zh-CN.
    return locale_scope.where(code: 'zh-TW') if %w[zh-HK zh-MO].include?(locale_code)

    return locale_scope.where('code like ?', "#{language_part_only}-%").order(:ui_available, :code)
  end

  def scripts?(script_subset)
    Rails.cache.fetch("locale_has_scripts/#{code}/#{script_subset}") do
      Script.listable(script_subset).joins(:localized_attributes).where(locale_id: id).any?
    end
  end

  def self.with_discussions
    locale_ids = Rails.cache.fetch('locale_with_discussions') do
      Discussion.visible.distinct.pluck(:locale_id)
    end
    where(id: locale_ids)
  end

  def self.load_locale_cache
    @locale_cache = Locale.all.index_by(&:code).freeze
  end

  def self.fetch_locale(code)
    @locale_cache[code.to_s]
  end

  def self.sort_by_name(locales, in_locale:)
    in_locale = in_locale.code if in_locale.is_a?(Locale)
    collator = ICU::Collation::Collator.new(in_locale)
    locales.sort { |a, b| collator.compare(a.best_name(in_locale:), b.best_name(in_locale:)) }
  end

  def self.locales_used_by_scripts
    Locale.where(id: LocalizedScriptAttribute.distinct(:locale_id).select(:locale_id))
  end
end
