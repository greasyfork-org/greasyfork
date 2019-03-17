class DisallowedCode < ApplicationRecord
	belongs_to :originating_script, class_name: 'Script', optional: true

	def readonly?
		true
	end

	def ob_code
		"403#{'%03i' % id}"
	end
end
