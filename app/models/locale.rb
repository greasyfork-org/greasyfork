class Locale < ApplicationRecord
  has_many :scripts, dependent: :restrict_with_exception
  has_many :locale_contributors, dependent: :destroy

  scope :with_listable_scripts, ->(script_subset) { joins(:scripts).where(scripts: Script.listable(script_subset).where_values_hash).distinct.order(:code) }

  def self.english
    Locale.find_by!(code: 'en')
  end

  def display_text
    "#{best_name} (#{code})"
  end

  def best_name
    native_name || english_name
  end

  # Returns the matching locales for the passed locale code, with locales with UI available first.
  def self.matching_locales(locale_code)
    l = where(code: locale_code).order([:ui_available, :code])
    return l unless l.empty?

    if locale_code.include?('-')
      locale_code = locale_code.split('-').first
      l = where(code: locale_code).order([:ui_available, :code])
      return l unless l.empty?
    end

    return Locale.none if locale_code.nil?

    return where(['code like ?', "#{locale_code}-%"]).order([:ui_available, :code])
  end

  def scripts?(script_subset)
    Rails.cache.fetch("locale_has_scripts/#{code}/#{script_subset}") do
      Script.listable(script_subset).joins(:localized_attributes).where(locale_id: id).any?
    end
  end
end
