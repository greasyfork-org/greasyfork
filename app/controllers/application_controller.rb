class ApplicationController < ActionController::Base
	protect_from_forgery with: :exception

	before_action :configure_permitted_parameters, if: :devise_controller?
	before_action :banned?

	include ApplicationHelper
	include LocalizedRequest

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
		devise_parameter_sanitizer.permit(:account_update, keys: [:name, :profile, :profile_markup, :preferred_markup, :locale_id, :author_email_notification_type_id, :show_ads, :show_sensitive, :flattr_username, :approve_redistribution])
	end

	def authorize_by_script_id
		render_access_denied if current_user.nil? or (!params[:script_id].nil? and Script.find(params[:script_id]).user_id != current_user.id)
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
				head 404
			}
		end
	end

	def render_deleted
		@text = 'Script has been deleted.'
		render 'home/error', status: 403, layout: 'application'
	end

	def render_locked
		@text = 'Script has been locked.'
		render 'home/error', status: 403, layout: 'application'
	end

	def render_access_denied
		@text = 'Access denied.'
		render 'home/error', status: 403, layout: 'application'
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

	def choose_ad_method(script=nil)
		return nil if sleazy?
		return nil if script&.sensitive
		return nil if current_user && !current_user.show_ads
		return 'gn' if script.nil?
		return 'ca' if script.localized_attribute_for('additional_info', I18n.locale).blank?
		return 'gn' if script.ad_method == 'ga'
		return script.ad_method || 'ca'
	end
	helper_method :choose_ad_method

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
