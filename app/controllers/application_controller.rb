class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_active_storage_url_options, if: -> { Rails.env.test? }

  include ApplicationHelper
  include ShowsAds
  include LocalizedRequest
  include Announcement
  include NotificationDisplay
  include RequestDebugging
  include BannedUser
  include Api
  include SiteSwitches

  if Rails.env.test?
    show_announcement key: :test_announcement,
                      show_if: -> { params[:test] == '1' },
                      content: 'This is a test announcement'
  end

  rescue_from ActiveRecord::RecordNotFound, with: :routing_error
  def routing_error
    respond_to do |format|
      format.html do
        @ad_method = choose_ad_method_for_error_page
        @routing_error = true
        render 'home/routing_error', status: :not_found, layout: 'application'
      end
      format.all do
        head :not_found, content_type: 'text/html'
      end
    end
  end

  rescue_from ActionController::UnknownFormat, with: :unknown_format
  def unknown_format
    head :not_acceptable, content_type: 'text/plain'
  end

  def self.cache_with_log(key, options = {})
    options[:version] = key.cache_version if key.respond_to?(:cache_version)
    key = "#{options.delete(:namespace)}/#{key.respond_to?(:cache_key) ? key.cache_key : key.to_s}" if options[:namespace]
    Rails.cache.fetch(key, options) do
      Rails.logger.warn("Cache miss - #{key} - #{options}") if Greasyfork::Application.config.log_cache_misses
      o = yield
      Rails.logger.warn("Cache stored - #{key} - #{options}") if Greasyfork::Application.config.log_cache_misses
      next o
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :locale_id])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :profile, :profile_markup, :preferred_markup, :locale_id, :show_ads, :show_sensitive, :filter_locale_default])
    devise_parameter_sanitizer.permit(:sign_in, keys: [:otp_attempt])
  end

  def authorize_by_script_id
    return if params[:script_id].blank?

    render_access_denied unless current_user && Script.find(params[:script_id]).users.include?(current_user)
  end

  def authorize_for_moderators_only
    render_access_denied if current_user.nil? || !current_user.moderator?
  end

  def authorize_by_user_id
    render_access_denied if current_user.nil? || (!params[:user_id].nil? && (params[:user_id].to_i != current_user.id))
  end

  def render_404(message = 'Script does not exist.')
    @ad_method = choose_ad_method_for_error_page
    render_error(404, message)
  end

  def render_error(code, message)
    respond_to do |format|
      format.html do
        @text = message
        render 'home/error', status: code, layout: 'application'
      end
      format.all do
        head code
      end
    end
  end

  def render_locked
    @text = 'Script has been locked.'
    render 'home/error', status: :forbidden, layout: 'application'
  end

  def render_access_denied
    @text = t('common.access_denied')
    render 'home/error', status: :forbidden, layout: 'application'
  end

  def redirect_to_slug(resource, id_param_name)
    if resource.nil?
      # no good
      render status: :not_found
      return
    end
    correct_id = resource.to_param
    if correct_id != params[id_param_name]
      url_params = { id_param_name => correct_id }
      retain_params = [:format]
      retain_params << :callback if params[:format] == 'jsonp'
      retain_params << :version if params[:controller] == 'scripts'
      retain_params.push(:v1, :v2) if params[:controller] == 'scripts' && params[:action] == 'diff'
      retain_params.each { |param_name| url_params[param_name] = params[param_name] }
      redirect_to(url_params, status: :moved_permanently)
      return true
    end
    return false
  end

  def clean_redirect_param(param_name)
    clean_redirect_value(params[param_name])
  end

  def clean_redirect_value(url)
    return nil if url.nil?

    begin
      u = URI.parse(url)
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
    return params[:callback] if /\A[a-zA-Z0-9_]{1,64}\z/.match?(params[:callback])

    return 'callback'
  end

  def ensure_default_additional_info(script, default_markup = 'html')
    script.localized_attributes.build({ attribute_key: 'additional_info', attribute_default: true, value_markup: default_markup }) unless script.localized_attributes_for('additional_info').any?(&:attribute_default)
  end

  def per_page(default: 50)
    pp = default
    pp = [params[:per_page].to_i, 200].min if !params[:per_page].nil? && params[:per_page].to_i > 0
    return pp
  end

  def page_number
    page = params[:page]&.to_i
    page = 1 if page.nil? || page < 1
    page
  end

  def cache_with_log(key, options = {}, &)
    self.class.cache_with_log(key, options, &)
  end

  helper_method :cache_with_log

  def get_script_from_input(value, allow_deleted: false, verify_existence: true)
    allowed_hosts = ['https://greasyfork.org', 'https://sleazyfork.org', 'https://cn-greasyfork.org']
    allowed_hosts += ['https://greasyfork.local', 'https://sleazyfork.local', 'https://cn-greasyfork.local'] unless Rails.env.production?

    return nil if value.blank?

    script_id = nil
    # Is it an ID?
    if value.to_i != 0
      script_id = value.to_i
    # A non-GF URL?
    elsif allowed_hosts.none? { |host| value.start_with?(host) && !value.start_with?('/') }
      return :non_gf_url
    # A GF URL?
    else
      url_match = %r{/scripts/([0-9]+)(-|$)}.match(value)
      return :non_script_url if url_match.nil?

      script_id = url_match[1]
    end

    return script_id unless verify_existence

    # Validate it's a good replacement
    begin
      script = Script.find(script_id)
    rescue ActiveRecord::RecordNotFound
      return :not_found
    end

    return :deleted if !allow_deleted && script.deleted?

    return script
  end

  def get_user_from_input(value)
    return nil if value.blank?

    if /\A[0-9]+\z/.match?(value)
      user_id = value.to_i
    elsif (url_match = %r{/users/([0-9]+)(-|$)}.match(value))
      user_id = url_match[1]
    end

    User.find_by(id: user_id) || User.find_by(name: value)
  end

  def set_cookie(key, value, httponly: true)
    cookies[key] = { value:, secure: Rails.env.production?, httponly: }
  end

  def check_read_only_mode
    render_error(503, "#{site_name} is in read-only mode while it's being upgraded. This upgrade should be complete within a few hours. You can still browse the site and install scripts while the upgrade proceeds.") if Rails.application.config.read_only_mode
  end

  def es_options_for_request
    with = case script_subset
           when :greasyfork
             { sensitive: false }
           when :sleazyfork
             { sensitive: true }
           else
             {}
           end
    with[:script_type] = Script.script_types[:public]
    with
  end

  def moderators_only
    render_access_denied unless current_user&.moderator?
  end

  def administrators_only
    render_access_denied unless current_user&.administrator?
  end

  def check_ip
    return unless current_user&.email_domain

    return unless Rails.application.config.ip_address_tracking

    if User.where(banned_at: 1.week.ago..)
           .where(current_sign_in_ip: request.remote_ip)
           .where(email_domain: current_user&.email_domain)
           .count >= 2
      @text = 'Your IP address has been banned.'
      render 'home/error', layout: 'application'
    end
  end

  def set_active_storage_url_options
    ActiveStorage::Current.url_options = { host: request.host, port: request.port }
  end
end
