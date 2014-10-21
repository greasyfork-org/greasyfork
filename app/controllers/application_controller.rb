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
		devise_parameter_sanitizer.for(:account_update) << :locale_id
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

	def authorize_by_user_id
		render_access_denied if current_user.nil? or (!params[:user_id].nil? and params[:user_id].to_i != current_user.id)
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

	def render_404(message = 'Script does not exist.')
		render :text => message, :status => 404, :layout => 'application'
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
		if (params[:controller] == "sessions" or params[:controller] == "registrations") and !params[:return_to].nil?
			v = clean_redirect_param(:return_to)
			session[:user_return_to] = v unless v.nil?
		end
	end

	def versionned_script(script_id, version_id)
		return nil if script_id.nil?
		script_id = script_id.to_i
		current_script = Script.includes({:user => {}, :license => {}, :localized_attributes => :locale}).find(script_id)
		return [current_script, current_script.get_newest_saved_script_version] if version_id.nil?
		version_id = version_id.to_i
		script_version = ScriptVersion.find(version_id)
		return nil if script_version.nil? or script_version.script_id != script_id
		script = Script.new

		# this is not versionned information
		script.script_type_id = current_script.script_type_id
		script.locale = current_script.locale

		current_script.localized_attributes.each{|la| script.build_localized_attribute(la)}

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
			url_params = {id_param_name => correct_id}
			retain_params = [:format]
			retain_params << :callback if params[:format] == 'jsonp'
			retain_params << :version if params[:controller] == 'scripts'
			retain_params.each{|param_name| url_params[param_name] = params[param_name]}
			redirect_to(url_params, :status => 301)
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
		{ :locale => I18n.locale }
	end

	before_filter :set_locale
	def set_locale
		# User chose "Help us translate" in the locale picker
		if params[:locale] == 'help'
			redirect_to Rails.configuration.help_translate_url
			return
		end

		# Locale is properly set
		if !params[:locale].nil?
			# Suggest a different locale if we think there's a better one. Only do it once per session.
			if current_user.nil? && cookies[:locale_suggested].nil?
				cookies[:locale_suggested] = true
				top, preferred = ApplicationController.detect_locale(current_user, request.headers['Accept-Language'])
				if top.code != params[:locale]
					flash.now[:notice] = "<b>#{view_context.link_to(t('common.suggest_locale', :locale => top.code, :locale_name => (top.native_name || top.english_name)), {:locale => top.code})}</b>".html_safe
				end
			end
			I18n.locale = params[:locale]
			return
		end

		# Don't want to redirect on POSTs and stuff, even if they're missing a locale
		if !request.get? or ['omniauth_callback', 'omniauth_failure'].include?(params[:action])
			I18n.locale = :en
			return
		end

		# Redirect if locale is a request param and not part of the url
		if !request.GET[:locale].nil?
			redirect_to url_for(params.merge(:only_path => true)), :status => 301
			return
		end

		# Detect language
		top, preferred = ApplicationController.detect_locale(current_user, request.headers['Accept-Language'])
		flash[:notice] = "<b>Greasy Fork is not available in #{preferred.english_name}. <a href=\"#{Rails.configuration.help_translate_url}\" target=\"_new\">You can change that.</a></b>".html_safe if !preferred.nil?
		redirect_to :locale => top.code
	end

	def clean_redirect_param(param_name)
		v = params[param_name]
		return nil if v.nil?
		begin
			u = URI.parse(v)
			p = u.path
			q = u.query
			f = u.fragment
			return p + (q.nil? ? '' : "?#{q}") + (f.nil? ? '' : "##{f}")
		rescue URI::InvalidURIError
			# forget it...
		end
		return nil
	end

	def clean_json_callback_param
		return params[:callback] if /\A[a-zA-Z0-9]{1,32}\z/ =~ params[:callback]
		return 'callback'
	end

	def ensure_default_additional_info(s)
		if !s.localized_attributes_for('additional_info').any?{|la| la.attribute_default}
			s.localized_attributes.build({:attribute_key => 'additional_info', :attribute_default => true})
		end
	end

	def get_per_page
		per_page = 50
		per_page = [params[:per_page].to_i, 200].min if !params[:per_page].nil? and params[:per_page].to_i > 0
		return per_page
	end

	# Determines a locale to use based on user preference and Accept_Language header.
	# Returns an array consisting of:
	#   The top locale we can display.
	#   A locale the user would prefer more, but we don't support (can be nil)
	def self.detect_locale(current_user, accept_language)
		lookup_locales = nil
		if !current_user.nil? && !current_user.locale.nil?
			lookup_locales = [current_user.locale.code]
		else
			lookup_locales = parse_accept_language(accept_language)
		end
		top_displayable_locale = nil
		top_undisplayable_locale = nil
		lookup_locales.each do |locale_code|
			locales = Locale.matching_locales(locale_code)
			locales.each do |l|
				if l.ui_available
					top_displayable_locale = l
					break
				end
				top_undisplayable_locale = l if top_undisplayable_locale.nil?
			end
			break if !top_displayable_locale.nil?
		end
		top_displayable_locale = Locale.where(:code => 'en').first if top_displayable_locale.nil?
		return [top_displayable_locale, top_undisplayable_locale]
	end

	# Returns an array of locales for the passed Accept-Language value
	def self.parse_accept_language(v)
		return [] if v.nil?
		return v.split(',').map{|r|
			# make sure the region is uppercase
			locale_parts = r.split(';').first.strip.split('-', 2)
			locale_parts[1].upcase! if locale_parts.length > 1
			next locale_parts.join('-')
		}
	end

end
