require 'memo_wise'

module LocalizedRequest
  extend ActiveSupport::Concern
  prepend MemoWise

  included do
    before_action :set_locale
    before_action :nobots_overriding_locale
    helper_method :request_locale, :overriding_locale?
  end

  def request_locale
    Locale.fetch_locale(I18n.locale)
  end
  memo_wise :request_locale

  def set_locale
    # User chose "Help us translate" in the locale picker
    if params[:locale] == 'help'
      redirect_to Rails.configuration.help_translate_url, allow_other_host: true
      return
    end

    # Don't want to redirect on POSTs and API stuff, even if they're missing a locale
    if !(request.get? || request.head?) ||
       %w[omniauth_callback omniauth_failure sso webhook user_js meta_js user_css meta_css].include?(params[:action]) ||
       action_name == 'routing_error' ||
       %w[js json jsonp].include?(params[:format])
      params[:locale] = I18n.locale_available?(params[:locale]) ? params[:locale] : 'en'
      I18n.locale = params[:locale]
      return
    end

    if cn_greasy? && params[:locale] && available_locales_for_domain.exclude?(params[:locale])
      redirect_to current_path_with_params(locale: nil, locale_override: nil), status: :found
      return
    end

    # Redirect a logged-in user to their preferred locale, if it's available
    if current_user&.locale_id && current_user.locale.ui_available && params[:locale] != current_user.locale.code && (!overriding_locale? || params[:locale].nil?)
      redirect_to current_path_with_params(locale: current_user.locale.code, locale_override: nil), status: :found
      return
    end

    # Redirect if locale is a request param and not part of the url
    if request.GET[:locale].present?
      redirect_to current_path_with_params, status: :moved_permanently
      return
    end

    # Locale is properly set
    if params[:locale].present?
      I18n.locale = params[:locale]
      if cookies[:locale_messaged].nil?
        # Only hassle the user about locales once per session.
        set_cookie(:locale_messaged, true)
        # Suggest a different locale if we think there's a better one.
        if current_user.nil?
          top, _preferred = detect_locale(current_user, request.headers['Accept-Language'])
          flash.now[:notice] = view_context.tag.b { view_context.link_to(t('common.suggest_locale', locale: top.code, locale_name: top.native_name || top.english_name, site_name:), { locale: top.code }) } if top.code != params[:locale]
        end
        if flash.now[:notice].nil?
          locale = Locale.fetch_locale(params[:locale])
          flash.now[:notice] = view_context.tag.b { view_context.link_to(t('common.incomplete_locale', locale_name: locale.native_name || locale.english_name, percent: view_context.number_to_percentage(locale.percent_complete, precision: 0), site_name:), Rails.configuration.help_translate_url, target: '_new') } if !locale.nil? && locale.percent_complete <= 95
        end
      end
      return
    end

    # Detect language
    top, preferred = detect_locale(current_user, request.headers['Accept-Language'])
    unless preferred.nil?
      flash[:notice] = view_context.tag.b { ("#{site_name} is not available in #{preferred.english_name}. " + view_context.link_to('You can change that.', Rails.configuration.help_translate_url, target: '_new')).html_safe }
      flash[:html_safe] = true
    end
    redirect_to current_path_with_params(locale: top.code), status: :found
  end

  def default_url_options(_options = {})
    h = { locale: I18n.locale }
    h[:locale_override] = '1' if overriding_locale?
    return h
  end

  # Determines a locale to use based on user preference and Accept_Language header.
  # Returns an array consisting of:
  #   The top locale we can display.
  #   A locale the user would prefer more, but we don't support (can be nil)
  def detect_locale(current_user, accept_language)
    return [current_user.locale, nil] if current_user&.locale&.ui_available

    top_displayable_locale = nil
    top_undisplayable_locale = current_user&.locale

    parse_accept_language(accept_language).each do |locale_code|
      locales = Locale.matching_locales(locale_code, chinese_only: cn_greasy?)
      locales.each do |l|
        if l.ui_available
          top_displayable_locale = l
          break
        end
        top_undisplayable_locale ||= l
      end
      break unless top_displayable_locale.nil?
    end

    top_displayable_locale = (cn_greasy? ? Locale.simplified_chinese : Locale.english) if top_displayable_locale.nil?
    return [top_displayable_locale, top_undisplayable_locale]
  end

  def detect_locale_code
    detect_locale(current_user, request.headers['Accept-Language']).first.code
  end

  # Returns an array of locales for the passed Accept-Language value
  def parse_accept_language(value)
    return [] if value.nil?

    return value.split(',').filter_map do |r|
      locale = r.split(';').first&.strip
      next nil unless locale

      # make sure the region is uppercase
      locale_parts = locale.split('-', 2)
      locale_parts[1].upcase! if locale_parts.length > 1
      next locale_parts.join('-')
    end
  end

  def overriding_locale?
    params[:locale_override] == '1'
  end

  def nobots_overriding_locale
    @bots = 'noindex' if overriding_locale?
  end
end
