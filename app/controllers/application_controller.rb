class ApplicationController < ActionController::Base
	# Prevent CSRF attacks by raising an exception.
	# For APIs, you may want to use :null_session instead.
	protect_from_forgery with: :exception

	before_filter :configure_permitted_parameters, if: :devise_controller?

	before_filter :store_location

	before_filter :banned?

protected

	def configure_permitted_parameters
		devise_parameter_sanitizer.for(:sign_up) << :name
		devise_parameter_sanitizer.for(:account_update) << :name
		devise_parameter_sanitizer.for(:account_update) << :profile
		devise_parameter_sanitizer.for(:account_update) << :profile_markup
		devise_parameter_sanitizer.for(:account_update) << :author_email_notification_type_id
	end

	def authorize_by_script_id
		render_access_denied if current_user.nil? or (!params[:script_id].nil? and Script.find(params[:script_id]).user_id != current_user.id)
	end

	def authorize_by_script_id_or_moderator
		return if !current_user.nil? and current_user.moderator?
		authorize_by_script_id
	end

	def authorize_for_moderators_only
		render_access_denied if current_user.nil? or !current_user.moderator?
	end

	def check_for_deleted(script)
		render_deleted if !script.nil? and !script.script_delete_type_id.nil? and (current_user.nil? or (current_user != script.user and !current_user.moderator?))
	end

	def check_for_deleted_by_id
		return if params[:id].nil?
		begin
			script = Script.find(params[:id])
		rescue ActiveRecord::RecordNotFound
			render_404
			return
		end
		check_for_deleted(script)
	end

	def check_for_deleted_by_script_id
		return if params[:script_id].nil?
		begin
			script = Script.find(params[:script_id])
		rescue ActiveRecord::RecordNotFound
			render_404
			return
		end
		check_for_deleted(script)
	end

	def check_for_locked_by_script_id
		return if params[:script_id].nil?
		begin
			script = Script.find(params[:script_id])
		rescue ActiveRecord::RecordNotFound
			render_404
			return
		end
		render_locked if script.locked and (current_user.nil? or !current_user.moderator?)
	end

	def render_404
		render :text => 'Script does not exist.', :status => 404, :layout => 'application'
	end

	def render_deleted
		render :text => 'Script has been deleted.', :status => 410, :layout => 'application'
	end

	def render_locked
		render :text => 'Script has been locked.', :status => 403, :layout => 'application'
	end

	def render_access_denied
		render :text => 'Access denied.', :status => 403, :layout => 'application'
	end

	# Devise seems to handle log-in-then-go-to fine for Rails stuff, but not for the forum. This adds support
	# via a "return_to" parameter.
	def store_location
		# Avoid an open redirect
		if (params[:controller] == "sessions" or params[:controller] == "registrations") and !params[:return_to].nil? and params[:return_to] =~ /\Ahttps?:\/\/greasyfork\.(org|local)\/.*/
			session[:user_return_to] = params[:return_to]
		end
	end

	def versionned_script(script_id, version_id)
		return nil if script_id.nil?
		script_id = script_id.to_i
		current_script = Script.includes([:user, :license]).find(script_id)
		return [current_script, current_script.get_newest_saved_script_version] if version_id.nil?
		version_id = version_id.to_i
		script_version = ScriptVersion.find(version_id)
		return nil if script_version.nil? or script_version.script_id != script_id
		script = Script.new

		# this is not versionned information
		script.script_type_id = current_script.script_type_id

		# if this is a library, the code might not have name and description
		script.name = current_script.name
		script.description = current_script.description

		script.apply_from_script_version(script_version)
		script.id = script_id
		script.updated_at = script_version.updated_at
		script.user = script_version.script.user
		script.created_at = current_script.created_at
		script.updated_at = script_version.updated_at
		# this is not necessarily accurate, as the revision the user picked may not have involved a code update
		script.code_updated_at = script_version.updated_at
		return [script, script_version]
	end

	def redirect_to_slug(resource, id_param_name)
		if resource.nil?
			# no good
			render :status => 404
			return
		end
		correct_id = resource.to_param
		if correct_id != params[id_param_name]
			params[id_param_name] = correct_id
			redirect_to params.merge(:only_path => true), :status => 301
			return true
		end
		return false
	end

	def banned?
		if current_user.present? && current_user.banned?
			sign_out current_user
			flash[:alert] = "This account has been banned."
			root_path
		end
	end

	def default_url_options(options={})
		# set locale on links, unless we're the default
		{ :locale => ((I18n.locale == I18n.default_locale) ? nil : I18n.locale) }
	end

	before_filter :set_locale
	def set_locale
		if params[:locale] == 'help'
			redirect_to Rails.configuration.help_translate_url
			return
		end
		if request.get?
			# strip /en/ if set, that's the default
			if params[:locale] == 'en'
				params[:locale] = nil
				# only_path - prevent open redirect via "host" parameter
				redirect_to url_for(params.merge(:only_path => true)), :status => 301
				return
			end
			# redirect if locale is a request param and not part of the url
			if !request.GET[:locale].nil?
				redirect_to url_for(params), :status => 301
				return
			end
		end
		# set locale based on parameter
		I18n.locale = params[:locale] || :en
	end
end
