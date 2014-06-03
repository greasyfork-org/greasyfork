class SessionsController < Devise::SessionsController

	def after_sign_in_path_for(resource)
		if resource.is_a?(User) && resource.banned?
			sign_out resource
			flash.delete(:notice) # get rid of "Signed in successfully."
			flash[:alert] = "This account has been banned."
			root_path
		else
			super
		end
	end

	# delete Vanilla cookies too
	def destroy
		cookies.delete 'Vanilla'
		cookies.delete 'Vanilla-Volatile'
		super
	end

end
