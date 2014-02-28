class ApplicationController < ActionController::Base
	# Prevent CSRF attacks by raising an exception.
	# For APIs, you may want to use :null_session instead.
	protect_from_forgery with: :exception

	before_filter :configure_permitted_parameters, if: :devise_controller?

	before_filter :store_location

protected

	def configure_permitted_parameters
		devise_parameter_sanitizer.for(:sign_up) << :name
		devise_parameter_sanitizer.for(:account_update) << :name
		devise_parameter_sanitizer.for(:account_update) << :profile
		devise_parameter_sanitizer.for(:account_update) << :profile_markup
	end

	def authorize_by_script_id
		render_access_denied if current_user.nil? or (!params[:script_id].nil? and Script.find(params[:script_id]).user_id != current_user.id)
	end

	def render_access_denied
		render :text => 'Access denied.', :status => 403, :layout => true
	end

	# Devise seems to handle log-in-then-go-to fine for Rails stuff, but not for the forum. This adds support
	# via a "return_to" parameter.
	def store_location
		# Avoid an open redirect
		if (params[:controller] == "sessions" or params[:controller] == "registrations") and !params[:return_to].nil? and params[:return_to] =~ /\Ahttps?:\/\/greasyfork\.(org|local)\/.*/
			session[:user_return_to] = params[:return_to]
		end
	end

end
