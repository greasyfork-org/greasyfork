class Locale < ActiveRecord::Base

	def display_text
		"#{native_name.nil? ? english_name : native_name} (#{code})"
	end
end
