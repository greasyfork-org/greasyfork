require 'active_support/concern'

module LocalizingModel
	extend ActiveSupport::Concern

	def default_localized_value_for(attr_name)
		la = default_localized_attribute_for(attr_name)
		return nil if la.nil?
		return la.attribute_value
	end

	def default_localized_attribute_for(attr_name)
		return localized_attributes_for(attr_name, nil, false).select{|la| la.attribute_default}.first
	end

	# Returns a localized value. locale can be a Locale, ID, code, or nil.
	def localized_value_for(attr_name, lookup_locale = nil, use_default = true)
		la = localized_attribute_for(attr_name, lookup_locale)
		return nil if la.nil?
		return la.attribute_value
	end

	# Returns a localized value. locale can be a Locale, ID, code, or nil.
	def localized_attribute_for(attr_name, lookup_locale = nil, use_default = true)
		las = localized_attributes_for(attr_name, lookup_locale)
		return nil if las.nil?
		return las.first
	end

	# Returns an array of LocalizedAttributes. locale can be a Locale, ID, code, or nil.
	def localized_attributes_for(attr_name, lookup_locale = nil, use_default = true)
		attrs = active_localized_attributes.select{|la|
			la.attribute_key.to_s == attr_name.to_s && 
			(
				lookup_locale.nil? ||
				(lookup_locale.is_a?(Integer) && la.locale_id == lookup_locale) ||
				((lookup_locale.is_a?(String) || lookup_locale.is_a?(Symbol)) && la.locale&.code == lookup_locale.to_s) ||
				(lookup_locale.is_a?(Locale) && la.locale == lookup_locale)
			)
		}
		# if there's no locale lookup, the default will already be included
		if use_default and !lookup_locale.nil?
			d = default_localized_attribute_for(attr_name) 
			attrs << d if !d.nil? and !attrs.include?(d)
		end
		return attrs
	end

	# Returns the active (i.e. not going to be deleted) localized_attributes
	def active_localized_attributes
		return localized_attributes.select{|la| !la.marked_for_destruction?}
	end

	# Returns an array of Locales this script has
	def available_locales
		return active_localized_attributes.map{|la| la.locale}.uniq
	end

	# Builds a localized attribute on this record based on the passed localized attribute and return it
	def build_localized_attribute(other_la)
		la = localized_attributes.build({:attribute_key => other_la.attribute_key, :attribute_value => other_la.attribute_value, :attribute_default => other_la.attribute_default, :locale => other_la.locale, :value_markup => other_la.value_markup})
		if la.respond_to?(:sync_identifier) && other_la.respond_to?(:sync_identifier)
			la.sync_identifier = other_la.sync_identifier
			la.sync_source_id = other_la.sync_source_id
		end
		return la
	end

	def delete_localized_attributes(key)
		localized_attributes_for(key).each {|la| la.mark_for_destruction}
	end

	module ClassMethods

	end

end
