require 'active_support/concern'

module LocalizingModel
  extend ActiveSupport::Concern

  def default_localized_value_for(attr_name)
    la = default_localized_attribute_for(attr_name)
    return nil if la.nil?

    return la.attribute_value
  end

  def default_localized_attribute_for(attr_name)
    return localized_attributes_for(attr_name, nil).find(&:attribute_default)
  end

  # Returns a localized value. locale can be a Locale, ID, code, or nil.
  def localized_value_for(attr_name, lookup_locale = nil)
    la = localized_attribute_for(attr_name, lookup_locale)
    return nil if la.nil?

    return la.attribute_value
  end

  # Returns a localized value. locale can be a Locale, ID, code, or nil.
  def localized_attribute_for(attr_name, lookup_locale = nil)
    las = localized_attributes_for(attr_name, lookup_locale)
    return nil if las.nil?

    return las.first
  end

  # Returns an array of LocalizedAttributes. locale can be a Locale, ID, code, or nil.
  def localized_attributes_for(attr_name, lookup_locale = nil)
    attr_name = attr_name.to_s
    # Optimize for the case when localized_names is already loaded. We don't want to load localized_names here because
    # it's possible that localized_attributes is already or will be loaded, and we want to avoid an additional query.
    la_scope = (attr_name == 'name' && localized_names.loaded?) ? localized_names : active_localized_attributes

    # Get the Locale object if we're not passed an ID or a Locale so that we don't have to dig into the locale object
    # for each record.
    lookup_locale = Locale.find_by(code: lookup_locale) if lookup_locale.is_a?(String) || lookup_locale.is_a?(Symbol)

    attrs = la_scope.select do |la|
      la.attribute_key.to_s == attr_name.to_s &&
        (
          lookup_locale.nil? ||
          (lookup_locale.is_a?(Integer) && la.locale_id == lookup_locale) ||
          (lookup_locale.is_a?(Locale) && la.locale_id == lookup_locale.id)
        )
    end
    # if there's no locale lookup, the default will already be included
    unless lookup_locale.nil?
      d = default_localized_attribute_for(attr_name)
      attrs << d if !d.nil? && attrs.exclude?(d)
    end
    return attrs
  end

  # Returns the active (i.e. not going to be deleted) localized_attributes
  def active_localized_attributes
    return localized_attributes.reject(&:marked_for_destruction?)
  end

  # Returns an array of Locales this script has
  def available_locales
    return active_localized_attributes.map(&:locale).uniq
  end

  # Builds a localized attribute on this record based on the passed localized attribute and return it
  def build_localized_attribute(other_la)
    la = localized_attributes.build({ attribute_key: other_la.attribute_key, attribute_value: other_la.attribute_value, attribute_default: other_la.attribute_default, locale: other_la.locale, value_markup: other_la.value_markup })
    la.sync_identifier = other_la.sync_identifier if la.respond_to?(:sync_identifier) && other_la.respond_to?(:sync_identifier)
    other_la.mentions.each do |mention|
      la.mentions.build(user_id: mention.user_id, text: mention.text)
    end
    return la
  end

  def delete_localized_attributes(key)
    localized_attributes_for(key).each(&:mark_for_destruction)
  end

  module ClassMethods
  end
end
