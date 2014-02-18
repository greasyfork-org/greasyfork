class DisallowedCode < ActiveRecord::Base

	def readonly?
		true
	end

end
