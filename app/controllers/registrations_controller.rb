# per https://github.com/plataformatec/devise/wiki/How-To:-Customize-the-redirect-after-a-user-edits-their-profile
class RegistrationsController < Devise::RegistrationsController
	include LoginMethods

	before_action :check_captcha, only: [:create]

	# https://github.com/plataformatec/devise/wiki/How-To%3a-Allow-users-to-edit-their-account-without-providing-a-password
	def update
		@user = User.find(current_user.id)

		successfully_updated = if needs_password?(@user, params)
			@user.update_with_password(devise_parameter_sanitizer.sanitize(:account_update))
		else
			# remove the virtual current_password attribute
			# update_without_password doesn't know how to ignore it
			params[:user].delete(:current_password)
			@user.update_without_password(devise_parameter_sanitizer.sanitize(:account_update))
		end

		if successfully_updated
			# Sign in the user bypassing validation in case their password changed
			bypass_sign_in(@user)
			# Show the message in their new locale
			set_flash_message :notice, :updated, {:locale => @user.available_locale_code}
			redirect_to after_update_path_for(@user)
		else
			render "edit"
		end
	end

protected

	def after_update_path_for(resource)
		# Use the user's locale after update
		stored_location_for(resource) || user_path(resource, (resource.available_locale_code.nil? ? {} : {:locale => resource.available_locale_code}))
	end

	def after_sign_in_path_for(resource)
		stored_location_for(resource) || user_path(resource)
	end

	def check_captcha
		unless verify_recaptcha
			self.resource = resource_class.new sign_up_params
			resource.validate # Look for any other validation errors besides Recaptcha
			set_minimum_password_length
			respond_with_navigational(resource) { render :new }
		end
	end

private

	def needs_password?(user, params)
		false
	end

end
