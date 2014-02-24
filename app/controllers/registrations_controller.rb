# per https://github.com/plataformatec/devise/wiki/How-To:-Customize-the-redirect-after-a-user-edits-their-profile
class RegistrationsController < Devise::RegistrationsController

protected

	def after_update_path_for(resource)
		user_path(resource)
	end

	def after_sign_in_path_for(resource)
		user_path(resource)
	end
end
