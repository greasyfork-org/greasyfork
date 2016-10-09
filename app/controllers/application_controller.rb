class ApplicationController < ActionController::Base
	# Prevent CSRF attacks by raising an exception.
	# For APIs, you may want to use :null_session instead.
	protect_from_forgery with: :exception

	before_filter :configure_permitted_parameters, if: :devise_controller?

	before_filter :banned?

	rescue_from ActiveRecord::RecordNotFound, :with => :routing_error
	def routing_error
		respond_to do |format|
			format.html {
				render 'home/routing_error', status: 404, layout: 'application'
			}
			format.all {
				render :nothing => true, :status => 404, :content_type => 'text/html'
			}
		end
	end

protected

	def configure_permitted_parameters
		devise_parameter_sanitizer.for(:sign_up) << :name
		devise_parameter_sanitizer.for(:account_update) << :name
		devise_parameter_sanitizer.for(:account_update) << :profile
		devise_parameter_sanitizer.for(:account_update) << :profile_markup
		devise_parameter_sanitizer.for(:account_update) << :preferred_markup
		devise_parameter_sanitizer.for(:account_update) << :locale_id
		devise_parameter_sanitizer.for(:account_update) << :author_email_notification_type_id
		devise_parameter_sanitizer.for(:account_update) << :show_ads
		devise_parameter_sanitizer.for(:account_update) << :show_sensitive
		devise_parameter_sanitizer.for(:account_update) << :flattr_username
		devise_parameter_sanitizer.for(:account_update) << :approve_redistribution
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
		if !script.nil? && (current_user.nil? || (current_user != script.user && !current_user.moderator?))
			if !script.script_delete_type_id.nil?
				if !script.replaced_by_script_id.nil?
					if params.include?(:script_id)
						redirect_to :script_id => script.replaced_by_script_id, :status => 301
					else
						redirect_to :id => script.replaced_by_script_id, :status => 301
					end
				else
					render_deleted
				end
			end
		end
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
		respond_to do |format|
			format.html {
				@text = message
				render 'home/error', status: 404, layout: 'application'
			}
			format.all {
				render nothing: true, status: 404
			}
		end
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

	def versionned_script(script_id, version_id)
		return nil if script_id.nil?
		script_id = script_id.to_i
		current_script = Script.includes({:user => {}, :license => {}, :localized_attributes => :locale, :compatibilities => :browser}).find(script_id)
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
		script.set_default_name
		# this is not necessarily accurate, as the revision the user picked may not have involved a code update
		script.code_updated_at = script_version.updated_at
		return [script, script_version]
	end

	# versionned_script loads a bunch of stuff we may not care about
	def minimal_versionned_script(script_id, version_id)
		script_version = ScriptVersion.includes(:script).where(script_id: script_id)
		if params[:version]
			script_version = script_version.find(version_id)
		else
			script_version = script_version.references(:script_versions).order('script_versions.id DESC').first
			raise ActiveRecord::RecordNotFound if script_version.nil?
		end
		return [script_version.script, script_version]
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
		h = { :locale => I18n.locale }
		h[:locale_override] = params[:locale_override] unless params[:locale_override].nil?
		return h
	end

	before_filter :set_locale
	def set_locale
		# User chose "Help us translate" in the locale picker
		if params[:locale] == 'help'
			redirect_to Rails.configuration.help_translate_url
			return
		end

		# Don't want to redirect on POSTs and API stuff, even if they're missing a locale
		if !(request.get? || request.head?) || ['omniauth_callback', 'omniauth_failure', 'sso', 'webhook', 'user_js', 'meta_js'].include?(params[:action]) || action_name == 'routing_error'
			params[:locale] = params[:locale] || 'en'
			I18n.locale = params[:locale]
			return
		end

		# Redirect a logged-in user to their preferred locale, if it's available
		if !current_user.nil? && !current_user.locale.nil? && current_user.locale.ui_available && params[:locale] != current_user.locale.code && (params[:locale_override].nil? || params[:locale].nil?)
			redirect_to url_for(params.merge(:only_path => true, :locale => current_user.locale.code, :locale_override => nil)), :status => 302
			return
		end

		# Redirect if locale is a request param and not part of the url
		if !request.GET[:locale].nil?
			redirect_to url_for(params.merge(:only_path => true)), :status => 301
			return
		end

		# Locale is properly set
		if !params[:locale].nil?
			I18n.locale = params[:locale]
			if cookies[:locale_messaged].nil?
				# Only hassle the user about locales once per session.
				cookies[:locale_messaged] = true
				# Suggest a different locale if we think there's a better one.
				if current_user.nil?
					top, preferred = ApplicationController.detect_locale(current_user, request.headers['Accept-Language'])
					if top.code != params[:locale]
						flash.now[:notice] = "<b>#{view_context.link_to(t('common.suggest_locale', locale: top.code, locale_name: (top.native_name || top.english_name), site_name: site_name), {:locale => top.code})}</b>".html_safe
					end
				end
				if flash.now[:notice].nil?
					locale = Locale.where(:code => params[:locale]).first
					if !locale.nil? && locale.percent_complete <= 95
						flash.now[:notice] = "<b><a href=\"#{Rails.configuration.help_translate_url}\" target=\"_new\">#{t('common.incomplete_locale', locale_name: (locale.native_name || locale.english_name), percent: view_context.number_to_percentage(locale.percent_complete, precision: 0), site_name: site_name)}</a></b>".html_safe
					end
				end
			end
			return
		end

		# Detect language
		top, preferred = ApplicationController.detect_locale(current_user, request.headers['Accept-Language'])
		flash[:notice] = "<b>Greasy Fork is not available in #{preferred.english_name}. <a href=\"#{Rails.configuration.help_translate_url}\" target=\"_new\">You can change that.</a></b>".html_safe if !preferred.nil?
		redirect_to url_for(params.merge(:only_path => true, :locale => top.code)), :status => 302
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
		return params[:callback] if /\A[a-zA-Z0-9_]{1,64}\z/ =~ params[:callback]
		return 'callback'
	end

	def ensure_default_additional_info(s, default_markup = 'html')
		if !s.localized_attributes_for('additional_info').any?{|la| la.attribute_default}
			s.localized_attributes.build({:attribute_key => 'additional_info', :attribute_default => true, :value_markup => default_markup})
		end
	end

	def get_per_page
		per_page = 50
		per_page = [params[:per_page].to_i, 200].min if !params[:per_page].nil? and params[:per_page].to_i > 0
		return per_page
	end

	RANDOM_OPTIONS = ['pw']
	def choose_ad_method(script)
		return nil if sleazy?
		return nil if script && script.sensitive
		return nil if !current_user.nil? && !current_user.show_ads
		return script.ad_method if script.ad_method
		return params[:ad] if RANDOM_OPTIONS.include?(params[:ad])
		return RANDOM_OPTIONS.sample
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

	def self.cache_with_log(key, options = {})
		Rails.cache.fetch(key, options) do
			Rails.logger.warn("Cache miss - #{key} - #{options}") if Greasyfork::Application.config.log_cache_misses
			o = yield
			Rails.logger.warn("Cache stored - #{key} - #{options}") if Greasyfork::Application.config.log_cache_misses
			next o
		end
	end

	def cache_with_log(key, options = {})
		self.class.cache_with_log(key, options) do
			yield
		end
	end

	def sleazy?
		['sleazyfork.org', 'sleazyfork.local'].include?(request.domain)
	end

	def site_name
		sleazy? ? 'Sleazy Fork' : 'Greasy Fork'
	end

	def script_subset
		return :sleazyfork if sleazy?
		return :greasyfork if !user_signed_in?
		return current_user.show_sensitive ? :all : :greasyfork
	end

	def handle_wrong_site(script)
		if !script.sensitive && sleazy?
			render_404 I18n.t('scripts.non_adult_content_on_sleazy')
			return true
		end
		if script.sensitive && script_subset == :greasyfork && script.user != current_user
			message = current_user.nil? ? view_context.it('scripts.adult_content_on_greasy_not_logged_in_error', login_link: new_user_session_path): view_context.it('scripts.adult_content_on_greasy_logged_in_error', edit_account_link: edit_user_registration_path)
			render_404 message
			return true
		end
		return false
	end

	helper_method :cache_with_log, :sleazy?, :script_subset, :site_name

end
