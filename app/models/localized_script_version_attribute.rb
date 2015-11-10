class LocalizedScriptVersionAttribute < ActiveRecord::Base

	belongs_to :script_version
	belongs_to :locale

	strip_attributes :only => [:attribute_key, :attribute_value]

	validates_presence_of :attribute_key, :attribute_value, :locale, :value_markup

end
