class SessionsController < Devise::SessionsController

	# delete Vanilla cookies too
	def destroy
		cookies.delete 'Vanilla'
		cookies.delete 'Vanilla-Volatile'
		super
	end

end
