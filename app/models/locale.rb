class Locale < ActiveRecord::Base

	has_many :scripts

	scope :with_listable_scripts, -> {joins(:scripts).where(Script.listable.where_values).uniq.order(:code)}

	def display_text
		"#{native_name.nil? ? english_name : native_name} (#{code})"
	end
end
