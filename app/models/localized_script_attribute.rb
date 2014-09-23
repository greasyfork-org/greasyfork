class LocalizedScriptAttribute < ActiveRecord::Base

	belongs_to :script
	belongs_to :locale

	strip_attributes :only => [:attribute_key, :attribute_value]

	def localized_meta_key
		return LocalizedScriptAttribute.localized_meta_key(attribute_key, locale, attribute_default)
	end

	def self.localized_meta_key(attr, locale, attribute_default)
		return '@' + attr.to_s + (attribute_default ? '' : ':' + locale.code)
	end
	
end
