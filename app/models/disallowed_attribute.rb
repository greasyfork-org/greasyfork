class DisallowedAttribute < ApplicationRecord

	def readonly?
		true
	end

	def ob_code
		"402#{'%03i' % id}"
	end

end
