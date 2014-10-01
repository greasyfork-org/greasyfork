class LocalizedScriptAttribute < ActiveRecord::Base

	belongs_to :script
	belongs_to :locale

	strip_attributes :only => [:attribute_key, :attribute_value]

	validates_presence_of :attribute_key, :attribute_value, :locale, :value_markup

	validates_format_of :sync_identifier, :with => URI::regexp(%w(http https)), :message => :script_sync_identifier_bad_protocol, :if => Proc.new {|r| r.sync_source_id == 1}

	def localized_meta_key
		return LocalizedScriptAttribute.localized_meta_key(attribute_key, locale, attribute_default)
	end

	def self.localized_meta_key(attr, locale, attribute_default)
		return '@' + attr.to_s + (attribute_default ? '' : ':' + locale.code)
	end
	
end
