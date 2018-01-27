module LocalizedRequest
  extend ActiveSupport::Concern

  included do 
    before_action :set_locale
  end
  
	def set_locale
		# User chose "Help us translate" in the locale picker
		if params[:locale] == 'help'
			redirect_to Rails.configuration.help_translate_url
			return
		end

		# Don't want to redirect on POSTs and API stuff, even if they're missing a locale
		if !(request.get? || request.head?) ||
				['omniauth_callback', 'omniauth_failure', 'sso', 'webhook', 'user_js', 'meta_js'].include?(params[:action]) ||
				action_name == 'routing_error' ||
				['js', 'json', 'jsonp'].include?(params[:format])
			params[:locale] = params[:locale] || 'en'
			I18n.locale = params[:locale]
			return
		end

		# Redirect a logged-in user to their preferred locale, if it's available
		if !current_user.nil? && !current_user.locale.nil? && current_user.locale.ui_available && params[:locale] != current_user.locale.code && (params[:locale_override].nil? || params[:locale].nil?)
			redirect_to current_path_with_params(locale: current_user.locale.code, locale_override: nil), :status => 302
			return
		end

		# Redirect if locale is a request param and not part of the url
		if !request.GET[:locale].nil?
			redirect_to current_path_with_params, :status => 301
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
					top, preferred = detect_locale(current_user, request.headers['Accept-Language'])
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
		top, preferred = detect_locale(current_user, request.headers['Accept-Language'])
		flash[:notice] = "<b>Greasy Fork is not available in #{preferred.english_name}. <a href=\"#{Rails.configuration.help_translate_url}\" target=\"_new\">You can change that.</a></b>".html_safe if !preferred.nil?
		redirect_to current_path_with_params(locale: top.code), :status => 302
	end

	def default_url_options(options={})
		h = { :locale => I18n.locale }
		h[:locale_override] = params[:locale_override] unless params[:locale_override].nil?
		return h
	end

	# Determines a locale to use based on user preference and Accept_Language header.
	# Returns an array consisting of:
	#   The top locale we can display.
	#   A locale the user would prefer more, but we don't support (can be nil)
	def detect_locale(current_user, accept_language)
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
	def parse_accept_language(v)
		return [] if v.nil?
		return v.split(',').map{|r|
			# make sure the region is uppercase
			locale_parts = r.split(';').first.strip.split('-', 2)
			locale_parts[1].upcase! if locale_parts.length > 1
			next locale_parts.join('-')
		}
	end

end
