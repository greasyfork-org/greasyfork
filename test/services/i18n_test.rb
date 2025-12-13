require 'test_helper'

class I18nTest < ActiveSupport::TestCase
  test 'all locales have the correct interpolation keys' do
    I18n.t('.')
    verify_i18n_tree([], YAML.load_file(Rails.root.join('config/locales/en.yml'))['en'])
  end

  def verify_i18n_tree(context, tree)
    tree.each do |key, value|
      case value
      when String
        verify_translations(context + [key], value)
      when Hash
        verify_i18n_tree(context + [key], value)
      when Array
        value.compact.each do |v|
          verify_translations(context + [key], v)
        end
      when TrueClass, FalseClass, Integer
        # Nothing
      else
        raise "Unexpected class for #{value}"
      end
    end
  end

  def verify_translations(context, english_text)
    english_interpolations = get_interpolations(english_text)
    Rails.application.config.available_locales.each do |locale|
      locale_text = I18n.backend.send(:translations).dig(locale.to_sym, *context.map(&:to_sym))
      next if locale_text.nil?

      locale_interpolations = get_interpolations(locale_text)
      # OK if they have less, but they can't have more.
      assert_empty locale_interpolations - english_interpolations, "Interpolations do not match for locale #{locale} and key #{context.join('.')}.\n\nEnglish text is: #{english_text}.\n\nTranslated text is: #{locale_text}"
    end
  end

  def get_interpolations(i18n_text)
    Array(i18n_text).select { |v| v.is_a?(String) }.map { |v| v.scan(/%{([^}:]*)[:}]/) }.flatten.sort
  end
end
