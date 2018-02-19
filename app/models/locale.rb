class Locale < ApplicationRecord

	has_many :scripts
	has_many :locale_contributors

	scope :with_listable_scripts, ->(script_subset) {joins(:scripts).where(scripts: Script.listable(script_subset).where_values_hash).distinct.order(:code)}

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
	def self.matching_locales(c)
		l = self.where(:code => c).order([:ui_available, :code])
		return l if !l.empty?
		if c.include?('-')
			c = c.split('-').first
			l = self.where(:code => c).order([:ui_available, :code])
			return l if !l.empty?
		end
		return self.where(['code like ?', c + '-%']).order([:ui_available, :code])
	end

end
