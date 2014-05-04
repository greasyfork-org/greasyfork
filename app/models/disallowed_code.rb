class DisallowedCode < ActiveRecord::Base

	def readonly?
		true
	end

	def ob_code
		"403#{'%03i' % id}"
	end

end
