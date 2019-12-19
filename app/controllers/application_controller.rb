class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :banned?

  include ApplicationHelper
  include ShowsAds
  include LocalizedRequest
  include Announcement

  show_announcement key: :test_announcement, show_if: -> { params[:test] == '1' }, content: "This is a test announcement" #if Rails.env.test?

  rescue_from ActiveRecord::RecordNotFound, :with => :routing_error
  def routing_error
    respond_to do |format|
      format.html {
        render 'home/routing_error', status: 404, layout: 'application'
      }
      format.all {
        head 404, content_type: 'text/html'
      }
    end
  end

  rescue_from ActionController::UnknownFormat, with: :unknown_format
  def unknown_format
    head 406, content_type: 'text/plain'
  end

protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :profile, :profile_markup, :preferred_markup, :locale_id, :author_email_notification_type_id, :show_ads, :show_sensitive, :flattr_username])
  end

  def authorize_by_script_id
    return unless params[:script_id].present?
    render_access_denied unless current_user && Script.find(params[:script_id]).users.include?(current_user)
  end

  def authorize_for_moderators_only
    render_access_denied if current_user.nil? or !current_user.moderator?
  end

  def authorize_by_user_id
    render_access_denied if current_user.nil? or (!params[:user_id].nil? and params[:user_id].to_i != current_user.id)
  end

  def render_404(message = 'Script does not exist.')
    respond_to do |format|
      format.html {
        @text = message
        render 'home/error', status: 404, layout: 'application'
      }
      format.all {
        head 404
      }
    end
  end

  def render_locked
    @text = 'Script has been locked.'
    render 'home/error', status: 403, layout: 'application'
  end

  def render_access_denied
    @text = 'Access denied.'
    render 'home/error', status: 403, layout: 'application'
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

  def self.cache_with_log(key, options = {})
    key = key.map{|k| k.respond_to?(:cache_key) ? k.cache_key : k} if key.is_a?(Array)
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

  def greasy?
    !sleazy?
  end

  def sleazy?
    ['sleazyfork.org', 'sleazyfork.local', 'www.sleazyfork.org'].include?(request.domain)
  end

  def site_name
    sleazy? ? 'Sleazy Fork' : 'Greasy Fork'
  end

  def script_subset
    return :sleazyfork if sleazy?
    return :greasyfork if !user_signed_in?
    return current_user.show_sensitive ? :all : :greasyfork
  end

  helper_method :cache_with_log, :sleazy?, :script_subset, :site_name

  def get_script_from_input(v)
    return nil if v.blank?

    replaced_by = nil
    script_id = nil
    # Is it an ID?
    if v.to_i != 0
      script_id = v.to_i
    # A non-GF URL?
    elsif !v.start_with?('https://greasyfork.org/')
      return :non_gf_url
    # A GF URL?
    else
      url_match = /\/scripts\/([0-9]+)(\-|$)/.match(v)
      return :non_script_url if url_match.nil?
      script_id = url_match[1]
    end

    # Validate it's a good replacement
    begin
      script = Script.find(script_id)
    rescue ActiveRecord::RecordNotFound
      return :not_found
    end

    return :deleted unless script.script_delete_type_id.nil?

    return script
  end
end
