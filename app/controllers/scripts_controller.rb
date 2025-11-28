require 'script_importer/script_syncer'
require 'csv'
require 'fileutils'
require 'cgi'
require 'css_to_js_converter'
require 'css_parser'
require 'js_parser'
require 'digest'
require 'data_centre_ips'

class ScriptsController < ApplicationController
  include ScriptAndVersions
  include PageCache
  include FileCaching

  MEMBER_AUTHOR_ACTIONS = [:sync_update, :update_promoted, :request_permanent_deletion, :unrequest_permanent_deletion, :update_promoted, :invite, :remove_author].freeze
  MEMBER_AUTHOR_OR_MODERATOR_ACTIONS = [:delete, :do_delete, :undelete, :do_undelete, :derivatives, :admin, :update_locale, :request_duplicate_check].freeze
  MEMBER_MODERATOR_ACTIONS = [:mark, :do_mark, :approve].freeze
  MEMBER_PUBLIC_ACTIONS = [:diff, :report, :accept_invitation].freeze
  MEMBER_PUBLIC_ACTIONS_WITH_SPECIAL_LOADING = [:show, :show_code, :user_js, :meta_js, :user_css, :meta_css, :feedback, :install_ping, :stats, :sync_additional_info_form].freeze

  before_action do
    case action_name.to_sym
    when *MEMBER_AUTHOR_ACTIONS
      @script = Script.find(params[:id])
      render_access_denied unless @script.users.include?(current_user)
      @bots = 'noindex'
    when *MEMBER_AUTHOR_OR_MODERATOR_ACTIONS
      @script = Script.find(params[:id])
      render_access_denied unless @script.users.include?(current_user) || current_user&.moderator?
      @bots = 'noindex'
    when *MEMBER_MODERATOR_ACTIONS
      unless current_user&.moderator?
        render_access_denied
        next
      end
      @script = Script.find(params[:id])
      @bots = 'noindex'
    when *MEMBER_PUBLIC_ACTIONS
      @script = Script.find(params[:id])
      set_bots_directive unless handle_publicly_deleted(@script)
    when *MEMBER_PUBLIC_ACTIONS_WITH_SPECIAL_LOADING
      # Nothing
    when *COLLECTION_PUBLIC_ACTIONS
      # Nothing
    when *COLLECTION_MODERATOR_ACTIONS
      unless current_user&.moderator?
        render_access_denied
        next
      end
      @bots = 'noindex'
    when *COLLECTION_LOGGED_IN_ACTIONS
      authenticate_user!
    else
      raise "Unknown action #{action_name}"
    end
  end

  before_action :check_read_only_mode, except: [:show, :show_code, :user_js, :meta_js, :user_css, :meta_css, :feedback, :stats, :diff, :derivatives, :index, :by_site]
  before_action :handle_api_request, only: [:show, :stats, :index, :by_site, :libraries, :code_search]

  skip_before_action :verify_authenticity_token, only: [:install_ping, :user_js, :meta_js, :user_css, :meta_css, :show, :show_code]

  # Avoid a query on these common actions - we don't need to restrict banned users from them.
  skip_before_action :banned?, only: [:user_js, :meta_js, :user_css, :meta_css]

  # The value a syncing additional info will have after syncing is added but before the first sync succeeds
  ADDITIONAL_INFO_SYNC_PLACEHOLDER = '(Awaiting sync)'.freeze

  include ScriptListings

  def show
    cachable_request = generally_cachable? && request.query_parameters.except(:version).empty?

    if cachable_request
      # We may not need everything. Put it off till later.
      @script = Script.find(params[:id].to_i)
    else
      @script, @script_version = versionned_script(params[:id], params[:version])
    end

    # Avoid cookie overflow when storing return_to in session - don't use the script name in the URL.
    @return_to = script_path(locale:, id: @script.id) if @script

    return if handle_publicly_deleted(@script)
    return if handle_wrong_url(@script, :id)

    respond_to do |format|
      format.html do
        provision_session_install_key(@script)

        page_key = "#{site_cache_key}/#{script_subset}/script/show/#{@script.id}/#{@script.updated_at&.to_i}/#{params[:version].to_i}/#{request_locale.id}" if cachable_request
        cache_page(page_key) do
          @script, @script_version = versionned_script(params[:id], params[:version]) if cachable_request

          if @script.nil?
            render_deleted(http_code: 410)
            return
          end

          @link_alternates = [
            { url: current_api_url_with_params(format: :json), type: 'application/json' },
            { url: current_api_url_with_params(format: :jsonp, callback: 'callback'), type: 'application/javascript' },
          ]
          @canonical_params = [:id, :version]
          set_bots_directive
          @ad_method = choose_ad_method_for_script(@script)
          @placed_ads = true
          show_integrity_hash_warning
          render_to_string
        end
      end
      format.js do
        redirect_to @script.code_path
      end
      format.json { render json: @script.as_json(include: :users, sleazy: sleazy?) }
      format.jsonp { render json: @script.as_json(include: :users, sleazy: sleazy?), callback: clean_json_callback_param }
      format.user_script_meta do
        route_params = { id: params[:id], name: @script.name, format: nil }
        route_params[:version] = params[:version] unless params[:version].nil?
        redirect_to meta_js_script_path(route_params)
      end
    end
  end

  def show_code
    @script, @script_version = versionned_script(params[:id], params[:version])

    return if handle_publicly_deleted(@script)

    # some weird safari client tries to do this
    if params[:format] == 'meta.js'
      redirect_to meta_js_script_path(params.merge({ name: @script.name, format: nil }))
      return
    end

    return if handle_wrong_url(@script, :id)

    respond_to do |format|
      format.html do
        provision_session_install_key(@script)
        @code = @script_version.rewritten_code
        set_bots_directive
        @canonical_params = [:id, :version]
        show_integrity_hash_warning

        @ad_method = choose_ad_method_for_script(@script)
        @placed_ads = @ad_method&.ea?
      end
      format.js do
        redirect_to @script.code_path
      end
      format.user_script_meta do
        route_params = { id: params[:id], name: @script.name, format: nil }
        route_params[:version] = params[:version] unless params[:version].nil?
        redirect_to meta_js_script_path(route_params)
      end
    end
  end

  def feedback
    cachable_request = generally_cachable? && request.query_parameters.empty?
    page_key = "#{site_cache_key}/script/feedback/#{params[:id]}/#{request_locale.id}" if cachable_request

    respond_to do |format|
      format.html do
        cache_page(page_key) do
          @script, @script_version = versionned_script(params[:id], params[:version])

          return if handle_publicly_deleted(@script)

          return if handle_wrong_url(@script, :id)

          @discussions = @script.discussions
                                .visible
                                .where(report_id: nil)
                                .includes(:stat_first_comment, :stat_last_replier, :poster)
                                .order(stat_last_reply_date: :desc)
                                .paginate(page: page_number, per_page: per_page(default: 25))
          @discussion = @discussions.build(discussion_category: DiscussionCategory.script_discussions, poster: current_user)
          @discussion.rating = Discussion::RATING_QUESTION if @discussion.by_script_author?

          @discussion.comments.build(text_markup: current_user&.preferred_markup)

          @subscribe = current_user&.subscribe_on_discussion

          set_bots_directive
          @canonical_params = [:id, :version]

          @ad_method = choose_ad_method_for_script(@script)
          @placed_ads = @ad_method&.ea?

          render_to_string
        end
      end
    end
  end

  def user_js
    script_id = params[:id].to_i
    script_version_id = params[:version].to_i

    unless update_host?
      script = Script.find(script_id)
      meta_request = request.headers['Accept']&.include?('text/x-userscript-meta')
      redirect_to(script.code_url(sleazy: sleazy?, cn_greasy: cn_greasy?, version_id: script_version_id, format_override: meta_request ? 'meta.js' : 'js'), status: :moved_permanently, allow_other_host: true)
      return
    end

    begin
      script, script_version = minimal_versionned_script(script_id, script_version_id)
    rescue ActiveRecord::RecordNotFound
      handle_code_not_found(script_id:)
      return
    end

    return if handle_replaced_script(script)

    if script.library? && request.path.ends_with?('.user.js')
      handle_code_not_available
      return
    end

    user_js_code = if script.delete_type_blanked?
                     script_version.generate_blanked_code
                   elsif script.deleted?
                     handle_code_not_available
                     return
                   elsif script.css?
                     unless script.css_convertible_to_js?
                       handle_code_not_available
                       return
                     end
                     CssToJsConverter.convert(script_version.rewritten_code)
                   else
                     script_version.rewritten_code
                   end

    unless script.library?
      meta_changes = if script_version_id == 0
                       # Set canonical update URLs.
                       {
                         downloadURL: script.code_url(sleazy: sleazy?, cn_greasy: cn_greasy?, format_override: 'js'),
                         updateURL: script.code_url(sleazy: sleazy?, cn_greasy: cn_greasy?, format_override: 'meta.js'),
                       }
                     else
                       # If the request specifies a specific version, the code will never change, so inform the manager not to check for updates.
                       { downloadURL: 'none' }
                     end

      user_js_code = JsParser.inject_meta(user_js_code, meta_changes)
    end

    code_time = (script_version_id == 0) ? script.code_updated_at : script_version.created_at
    cache_code_request(user_js_code, script_id:, script_version_id_param: script_version_id, extension: script.library? ? '.js' : '.user.js', code_updated_at: code_time)

    headers['Last-Modified'] = code_time.httpdate
    render body: user_js_code, content_type: 'text/javascript'
  end

  def user_css
    script_id = params[:id].to_i
    script_version_id = params[:version].to_i

    unless update_host?
      script = Script.find(script_id)
      redirect_to(script.code_url(sleazy: sleazy?, cn_greasy: cn_greasy?, version_id: script_version_id), status: :moved_permanently, allow_other_host: true)
      return
    end

    begin
      script, script_version = minimal_versionned_script(script_id, script_version_id)
    rescue ActiveRecord::RecordNotFound
      handle_code_not_found(script_id:)
      return
    end

    return if handle_replaced_script(script)

    if script.js?
      head :not_found
      return
    end

    user_css_code = if script.delete_type_blanked?
                      script_version.generate_blanked_code
                    elsif script.deleted?
                      head :not_found
                      return
                    else
                      script_version.rewritten_code
                    end

    meta_changes = if script_version_id == 0
                     # Set canonical update URLs.
                     {
                       downloadURL: script.code_url(sleazy: sleazy?, format_override: 'css'),
                       updateURL: script.code_url(sleazy: sleazy?, format_override: 'meta.css'),
                     }
                   else
                     # If the request specifies a specific version, the code will never change, so inform the manager not to check for updates.
                     { downloadURL: 'none' }
                   end

    user_css_code = script_version.parser_class.inject_meta(user_css_code, meta_changes)

    code_time = (script_version_id == 0) ? script.code_updated_at : script_version.created_at
    cache_code_request(user_css_code, script_id:, script_version_id_param: script_version_id, extension: '.user.css', code_updated_at: code_time)

    headers['Last-Modified'] = code_time.httpdate
    render body: user_css_code, content_type: 'text/css'
  end

  def meta_js
    handle_meta_request(:js)
  end

  def meta_css
    handle_meta_request(:css)
  end

  def install_ping
    if Rails.env.test?
      ip, script_id = ScriptsController.per_user_stat_params(request, params)
      Script.record_install(script_id, ip)
      head :no_content
      return
    end

    # verify for CSRF, but do it in a way that avoids an exception. Prevents monitoring from going nuts.
    unless verified_request?
      head :unprocessable_content
      return
    end
    ip, script_id = ScriptsController.per_user_stat_params(request, params)
    if ip.nil? || script_id.nil?
      head :unprocessable_content
      return
    end

    unless get_script_from_input(request.headers['Referer'], verify_existence: false) == script_id
      Rails.logger.warn("Install not recorded for script #{script_id} and IP #{ip} - referer does not match.")
      head :no_content
      return
    end

    unless install_keys.any? { |install_key| Digest::SHA1.hexdigest(request.remote_ip + script_id + install_key) == params[:ping_key] }
      Rails.logger.warn("Install not recorded for script #{script_id} and IP #{ip} - install key does not match.")
      head :no_content
      return
    end

    if DataCentreIps.new.data_centre?(ip)
      Rails.logger.warn("Install not recorded for script #{script_id} and IP #{ip} - appears to be a data centre.")
      head :no_content
      return
    end

    passed_checks = PingRequestCheckingService.check(request)
    session[PingRequestChecking::SessionInstallKey::SESSION_KEY] -= [script_id.to_i] if session[PingRequestChecking::SessionInstallKey::SESSION_KEY]
    unless passed_checks.count == PingRequestCheckingService::STRATEGIES.count
      Rails.logger.warn("Install not recorded for script #{script_id} and IP #{ip} - only passed ping checks: #{passed_checks.join(', ')}")
      head :no_content
      return
    end

    ip = Array.new(4) { rand(256) }.join('.') unless Rails.application.config.ip_address_tracking
    Script.record_install(script_id, ip)
    head :no_content
  end

  def diff
    return if handle_wrong_url(@script, :id)

    versions = [params[:v1].to_i, params[:v2].to_i]
    @old_version = ScriptVersion.find(versions.min)
    @new_version = ScriptVersion.find(versions.max)
    if @old_version.nil? || @new_version.nil? || (@old_version.script_id != @script.id) || (@new_version.script_id != @script.id)
      @text = 'Invalid versions provided.'
      render 'home/error', status: :bad_request, layout: 'application'
      return
    end
    @context = 3
    @context = params[:context].to_i if !params[:context].nil? && params[:context].to_i.between?(0, 10_000)
    diff_options = ["-U #{@context}"]
    diff_options << '-w' if !params[:w].nil? && params[:w] == '1'
    @diff = Diffy::Diff.new(@old_version.code, @new_version.code, include_plus_and_minus_in_html: true, include_diff_info: true, diff: diff_options).to_s(:html).html_safe
    @bots = 'noindex'
    @canonical_params = [:id, :v1, :v2, :context, :w]
  end

  def sync_update
    unless params['stop-syncing'].nil?
      @script.sync_type = nil
      @script.last_attempted_sync_date = nil
      @script.last_successful_sync_date = nil
      @script.sync_identifier = nil
      @script.sync_error = nil
      @script.localized_attributes_for('additional_info').each do |la|
        la.sync_identifier = nil
      end
      @script.save(validate: false)
      flash.now[:notice] = t('scripts.sync_turned_off')
      redirect_to @script
      return
    end

    @script.assign_attributes(params.expect(script: [:sync_type, :sync_identifier]))
    @script.sync_identifier = ScriptImporter::UrlImporter.fix_sync_id(@script.sync_identifier) if @script.sync_identifier

    # additional info syncs. and new ones and update existing ones to add/update sync_identifiers
    if params['additional_info_sync']
      current_additional_infos = @script.localized_attributes_for('additional_info')
      # keep track of the ones we see - ones we don't will be unsynced or deleted
      unused_additional_infos = current_additional_infos.dup
      params['additional_info_sync'].each do |_index, sync_params|
        # if it's blank it will be ignored (if new) or no longer synced (if existing)
        form_is_blank = (sync_params['attribute_default'] != 'true' && sync_params['locale'].nil?) || sync_params['sync_identifier'].blank?
        existing = current_additional_infos.find { |la| (la.attribute_default && sync_params['attribute_default'] == 'true') || la.locale_id == sync_params['locale'].to_i }
        if existing.nil?
          next if form_is_blank

          attribute_default = (sync_params['attribute_default'] == 'true')
          @script.localized_attributes.build(attribute_key: 'additional_info', sync_identifier: sync_params['sync_identifier'], value_markup: sync_params['value_markup'], locale_id: attribute_default ? @script.locale_id : sync_params['locale'], attribute_value: ADDITIONAL_INFO_SYNC_PLACEHOLDER, attribute_default:)
        else
          unless form_is_blank
            unused_additional_infos.delete(existing)
            existing.sync_identifier = sync_params['sync_identifier']
            existing.value_markup = sync_params['value_markup']
          end
        end
      end
      unused_additional_infos.each do |la|
        # Keep the existing if it had anything but the placeholder
        if la.attribute_value == ADDITIONAL_INFO_SYNC_PLACEHOLDER
          la.mark_for_destruction
        else
          la.sync_identifier = nil
        end
      end
    end

    save_record = params[:preview].nil? && params['add-synced-additional-info'].nil?

    # preview for people with JS disabled
    unless params[:preview].nil?
      @preview = {}
      preview_params = params['additional_info_sync'][params[:preview]]
      begin
        text = ScriptImporter::BaseScriptImporter.download(preview_params[:sync_identifier])
        @preview[params[:preview].to_i] = view_context.format_user_text(text, preview_params[:value_markup])
      rescue ArgumentError, OpenURI::HTTPError => e
        @preview[params[:preview].to_i] = e.to_s
      end
    end

    # add sync localized additional info for people with JS disabled
    @script.localized_attributes.build({ attribute_key: 'additional_info', attribute_default: false }) unless params['add-synced-additional-info'].nil?

    if !save_record || !@script.save
      ensure_default_additional_info(@script, current_user.preferred_markup)
      render :admin
      return
    end
    unless params['update-and-sync'].nil?
      case ScriptImporter::ScriptSyncer.sync(@script)
      when :success
        flash[:notice] = t('scripts.sync_successful')
      when :unchanged
        flash[:notice] = t('scripts.sync_no_changes')
      when :failure
        flash[:notice] = t('scripts.sync_error', error: @script.sync_error)
      end
    end
    redirect_to @script
  end

  def delete; end

  def do_delete
    # Handle replaced by
    replaced_by = get_script_from_input(params[:replaced_by_script_id])
    case replaced_by
    when :non_gf_url, :non_script_url
      @script.errors.add(:replaced_by_script_id, I18n.t('errors.messages.must_be_greasy_fork_script', site_name:))
      render :delete
      return
    when :not_found
      @script.errors.add(:replaced_by_script_id, :not_found)
      render :delete
      return
    when :deleted
      @script.errors.add(:replaced_by_script_id, :cannot_be_deleted_reference)
      render :delete
      return
    end

    if replaced_by && @script.id == replaced_by.id
      @script.errors.add(:replaced_by_script_id, :cannot_be_self_reference)
      render :delete
      return
    end

    @script.replaced_by_script = replaced_by

    if current_user.moderator? && @script.users.exclude?(current_user)
      @script.locked = params[:locked].nil? ? false : params[:locked]
      ma = ModeratorAction.new
      ma.moderator = current_user
      ma.script = @script
      ma.action_taken = @script.locked ? :delete_and_lock : :delete
      ma.reason = params[:reason]
      @script.delete_reason = params[:reason]
      ma.save!
      @script.ban_all_authors!(moderator: current_user, reason: params[:reason]) if params[:banned]
    end
    @script.permanent_deletion_request_date = nil if @script.locked
    @script.delete_type = params[:delete_type]
    @script.save(validate: false)
    redirect_to @script
  end

  def do_undelete
    if @script.locked? && !current_user&.moderator?
      render_locked
      return
    end

    if current_user.moderator? && @script.users.exclude?(current_user)
      ma = ModeratorAction.new
      ma.moderator = current_user
      ma.script = @script
      ma.action_taken = :undelete
      ma.reason = params[:reason]
      ma.save!
      @script.locked = false
      if params[:unbanned]
        @script.users.select(&:banned?).each do |user|
          ma_ban = ModeratorAction.new
          ma_ban.moderator = current_user
          ma_ban.user = user
          ma_ban.action_taken = :unban
          ma_ban.reason = params[:reason]
          ma_ban.save!
          user.banned_at = nil
          user.save!
        end
      end
    end
    @script.delete_type = nil
    @script.replaced_by_script_id = nil
    @script.delete_reason = nil
    @script.permanent_deletion_request_date = nil
    @script.save(validate: false)
    redirect_to @script
  end

  def request_permanent_deletion
    if @script.locked
      flash[:notice] = I18n.t('scripts.delete_permanently_rejected_locked')
      redirect_to root_path
      return
    end
    @script.delete_type = 'keep'
    @script.permanent_deletion_request_date = DateTime.now
    @script.save(validate: false)
    flash[:notice] = I18n.t('scripts.delete_permanently_notice')
    redirect_to @script
  end

  def unrequest_permanent_deletion
    @script.permanent_deletion_request_date = nil
    @script.save(validate: false)
    flash[:notice] = I18n.t('scripts.cancel_delete_permanently_notice')
    redirect_to @script
  end

  def mark
    ma = ModeratorAction.new
    ma.moderator = current_user
    ma.script = @script
    ma.reason = params[:reason]

    case params[:mark]
    when 'adult'
      @script.sensitive = true
      @script.marked_adult_by_user = current_user
      ma.action_taken = :mark_adult
    when 'not_adult'
      @script.sensitive = false
      @script.not_adult_content_self_report_date = nil
      ma.action_taken = :mark_not_adult
    when 'clear_not_adult'
      @script.not_adult_content_self_report_date = nil
    else
      @text = "Can't do that!"
      render 'home/error', status: :not_acceptable, layout: 'application'
      return
    end

    ma.save! unless ma.action_taken.nil?

    @script.save!
    flash[:notice] = 'Script updated.' # rubocop:disable Rails/I18nLocaleTexts
    redirect_to @script
  end

  def stats
    cachable_request = generally_cachable? && request.query_parameters.empty?
    page_key = "#{site_cache_key}/script/stats/#{params[:id].to_i}/#{request_locale.id}" if cachable_request

    cache_page(page_key) do
      @script, @script_version = versionned_script(params[:id], params[:version])

      return if handle_publicly_deleted(@script)

      return if handle_wrong_url(@script, :id)

      if request.format.html?
        @start_date = case params[:period]
                      when 'year'
                        1.year.ago.to_date
                      when 'all'
                        nil
                      else
                        30.days.ago.to_date
                      end
      end

      install_sql = "SELECT install_date, installs FROM install_counts where script_id = #{Script.connection.quote(@script.id)}"
      install_sql += " and install_date >= #{Script.connection.quote(@start_date)}" if @start_date
      install_values = Script.connection.select_rows(install_sql).to_h

      daily_install_sql = "SELECT DATE(install_date) d, COUNT(*) FROM daily_install_counts where script_id = #{Script.connection.quote(@script.id)}"
      daily_install_sql += " and install_date >= #{Script.connection.quote(@start_date)}" if @start_date
      daily_install_sql += ' GROUP BY d'
      daily_install_values = Script.connection.select_rows(daily_install_sql).to_h

      update_check_sql = "SELECT update_check_date, update_checks FROM update_check_counts where script_id = #{@script.id}"
      update_check_sql += " and update_check_date >= #{Script.connection.quote(@start_date)}" if @start_date
      update_check_values = Script.connection.select_rows(update_check_sql).to_h

      @stats = {}
      update_check_start_date = Date.parse('2014-10-23')
      ([@start_date, @script.created_at.to_date].compact.max..Time.now.utc.to_date).each do |d|
        stat = {}
        stat[:installs] = install_values[d] || daily_install_values[d] || 0
        # this stat not available before that date
        stat[:update_checks] = (d >= update_check_start_date) ? (update_check_values[d] || 0) : nil
        @stats[d] = stat
      end
      respond_to do |format|
        format.html do
          @bots = 'noindex' unless params[:period].nil?
          @canonical_params = [:id, :version]
          set_bots_directive
          render_to_string
        end
        format.csv do
          data = CSV.generate do |csv|
            csv << ['Date', 'Installs', 'Update checks']
            @stats.each do |d, stat|
              csv << [d, stat.values].flatten
            end
          end
          render plain: data
          response.content_type = 'text/csv'
        end
        format.json do
          cache_request(@stats.to_json) if request.fullpath.ends_with?('json')
          render json: @stats
        end
      end
    end
  end

  DERIVATIVE_SCORES = [
    [:high, 0.95],
    [:medium, 0.85],
    [:low, 0.75],
  ].freeze

  def derivatives
    return if redirect_to_slug(@script, :id)

    # Include the inverse as well so that we can notice new/updated scripts that are similar to this. If we have the
    # relation both forward and backward, take the higher score.
    @similarities = []
    @script.script_similarities.includes(:other_script).where(similarity: DERIVATIVE_SCORES.map(&:last).min..).order(similarity: :desc, id: :asc).each do |ss|
      @similarities << [ss.other_script, ss.similarity] if current_user&.moderator? || !ss.other_script.deleted?
    end
    # If we haven't run the forward, don't bother with the backward.
    if @similarities.any?
      ScriptSimilarity.where(other_script: @script).where(similarity: DERIVATIVE_SCORES.map(&:last).min..).order(similarity: :desc, id: :asc).each do |ss|
        @similarities << [ss.script, ss.similarity] if current_user&.moderator? || !ss.script.deleted?
      end
      @similarities = @similarities.sort_by(&:last).reverse.uniq(&:first).first(100)
    end

    @canonical_params = [:id]
  end

  def admin
    # For sync section
    @script.localized_attributes.build({ attribute_key: 'additional_info', attribute_default: true }) if @script.localized_attributes_for('additional_info').empty?

    @context = 3
    @context = params[:context].to_i if !params[:context].nil? && params[:context].to_i.between?(0, 10_000)

    return if params[:compare].blank?

    diff_options = ["-U #{@context}"]
    diff_options << '-w' if !params[:w].nil? && params[:w] == '1'
    @other_script = get_script_from_input(params[:compare], allow_deleted: true)

    if @other_script.is_a?(Script)
      if params[:terser] == '1'
        unless @script.cleaned_code && @other_script.cleaned_code
          @diff_error = flash.now[:notice] = t('.compare_cleaned_code_unavailable')
          return
        end
        other_code = @other_script.cleaned_code.code
        this_code = @script.cleaned_code.code
      else
        other_code = @other_script.newest_saved_script_version.code
        this_code = @script.newest_saved_script_version.code
      end
      @diff = Diffy::Diff.new(other_code, this_code, include_plus_and_minus_in_html: true, include_diff_info: true, diff: diff_options)
    else
      @diff_error = flash.now[:notice] = t('.compare_must_be_local_url', site_name:)
    end
  end

  def update_promoted
    promoted_script = get_script_from_input(params[:promoted_script_id])
    case promoted_script
    when :non_gf_url
      @script.errors.add(:promoted_script_id, I18n.t('errors.messages.must_be_greasy_fork_script', site_name:))
      render :admin
      return
    when :non_script_url
      @script.errors.add(:promoted_script_id, I18n.t('errors.messages.must_be_greasy_fork_script', site_name:))
      render :admin
      return
    when :not_found
      @script.errors.add(:promoted_script_id, :not_found)
      render :admin
      return
    when :deleted
      @script.errors.add(:promoted_script_id, :cannot_be_deleted_reference)
      render :admin
      return
    end

    if promoted_script == @script
      @script.errors.add(:promoted_script_id, :cannot_be_self_reference)
      render :admin
      return
    end

    if promoted_script && !@script.sensitive? && promoted_script.sensitive?
      @script.errors.add(:promoted_script_id, :cannot_be_used_with_this_script)
      render :admin
      return
    end

    @script.promoted_script = promoted_script
    @script.save!

    flash[:notice] = I18n.t('scripts.updated')
    redirect_to admin_script_path(@script)
  end

  def sync_additional_info_form
    render partial: 'sync_additional_info', locals: { la: LocalizedScriptAttribute.new({ attribute_default: false }), index: params[:index].to_i }
  end

  def update_locale
    update_params = params.expect(script: [:locale_id])
    if @script.update(update_params)
      unless @script.users.include?(current_user)
        ModeratorAction.create!(script: @script, moderator: current_user, action_taken: :update_locale, reason: "Changed to #{@script.locale.code}#{' (auto-detected)' if update_params[:locale_id].blank?}")
      end
      flash.now[:notice] = I18n.t('scripts.updated')
      redirect_to admin_script_path(@script)
      return
    end

    render :admin
  end

  def invite
    user_url_match = %r{https://(?:greasyfork|sleazyfork)\.org/(?:[a-zA-Z-]+/)?users/([0-9]+)}.match(params[:invited_user_url])

    unless user_url_match
      flash[:alert] = t('scripts.invitations.invalid_user_url')
      redirect_to admin_script_path(@script)
      return
    end

    user_id = user_url_match[1]
    user = User.find_by(id: user_id)

    unless user
      flash[:alert] = t('scripts.invitations.invalid_user_url')
      redirect_to admin_script_path(@script)
      return
    end

    if @script.users.include?(user)
      flash[:alert] = t('scripts.invitations.already_author')
      redirect_to admin_script_path(@script)
      return
    end

    invitation = @script.script_invitations.create!(
      invited_user: user,
      expires_at: ScriptInvitation::VALIDITY_PERIOD.from_now
    )
    ScriptInvitationMailer.invite(invitation, site_name).deliver_later
    flash[:notice] = t('scripts.invitations.sent')
    redirect_to admin_script_path(@script)
  end

  def accept_invitation
    authenticate_user!

    ais = AcceptInvitationService.new(@script, current_user)

    unless ais.valid?
      flash[:alert] = t(ais.error)
      redirect_to script_path(@script)
      return
    end

    ais.accept!

    flash[:notice] = t('scripts.invitations.invitation_accepted')
    redirect_to script_path(@script)
  end

  def remove_author
    user = User.find(params[:user_id])
    if @script.authors.count < 2 || @script.authors.where(user:).none?
      flash[:error] = t('.failure')
      return
    end

    @script.authors.find_by!(user:).destroy!
    flash[:notice] = t('.success', user_name: user.name)
    redirect_to script_path(@script)
  end

  def approve
    @script.update!(review_state: 'approved')
    flash[:notice] = 'Marked as approved.' # rubocop:disable Rails/I18nLocaleTexts
    redirect_to clean_redirect_param(:return_to) || script_path(@script)
  end

  def request_duplicate_check
    ScriptDuplicateCheckerJob.set(queue: 'user_low').perform_async(@script.id)
    flash[:notice] = t('scripts.derivatives_similiar_queued')
    flash[:duplicates_enqueued] = true
    redirect_to derivatives_script_path(@script)
  end

  # Returns IP and script ID. They will be nil if not valid.
  def self.per_user_stat_params(request, params)
    # Get IP in a way that avoids an exception. Prevents monitoring from going nuts.
    ip = nil
    begin
      ip = request.remote_ip
    rescue ActionDispatch::RemoteIp::IpSpoofAttackError
      # do nothing, ip remains nil
    end
    # strip the slug
    script_id = params[:id].to_i.to_s
    return [ip, script_id]
  end

  private

  def handle_replaced_script(script)
    if !script.replaced_by_script_id.nil? && script.replaced_by_script && script.delete_type_redirect?
      redirect_to(script.replaced_by_script.code_path, status: :moved_permanently)
      return true
    end
    return false
  end

  def cache_request(response_body)
    # Cache dir + request path without leading slash. Ensure it's actually under the cache dir to prevent
    # directory traversal.
    cache_request_portion = CGI.unescape(request.fullpath[1..])

    return unless cache_request_portion.valid_encoding?

    cache_path = Rails.application.config.script_page_cache_directory.join(cache_request_portion).cleanpath
    return unless cache_path.to_s.start_with?(Rails.application.config.script_page_cache_directory.to_s)

    # Make sure each portion is under the filesystem limit
    return unless cache_path.to_s.split('/').all? { |portion| portion.bytesize <= 255 }

    file_cache_content(cache_path, response_body)
  end

  def cache_code_request(response_body, script_id:, script_version_id_param:, extension:, code_updated_at:)
    script_version_id_param = script_version_id_param.to_i

    base_path = Rails.application.config.cached_code_path.join(site_code_cache_key)

    base_path = if script_version_id_param == 0
                  base_path.join('latest', 'scripts', "#{script_id}#{extension}")
                else
                  base_path.join('versioned', 'scripts', script_id.to_s, "#{script_version_id_param}#{extension}")
                end

    file_cache_content(base_path.cleanpath, response_body, update_time: code_updated_at)
  end

  # Logic for code requests where the script does not exist (yet or anymore)
  def handle_code_not_found(script_id:)
    # If that ID hasn't been used yet, don't 410 it, as we want it to work when it does exist.
    if script_id > Script.maximum(:id)
      handle_code_not_available
      return
    end

    response.headers['Cache-Control'] = 'public,max-age=604800'
    head :gone
  end

  # Logic for code requests where we don't serve up code, but we may in the future (e.g. by soft-undeletion)
  def handle_code_not_available
    response.headers['Cache-Control'] = 'public,max-age=600'
    head :not_found
  end

  def handle_wrong_url(resource, id_param_name)
    raise ActiveRecord::RecordNotFound if resource.nil?
    return true if handle_wrong_site(resource)
    return true if params[:format] != 'json' && redirect_to_slug(resource, id_param_name)

    return false
  end

  # versionned_script loads a bunch of stuff we may not care about
  def minimal_versionned_script(script_id, version_id)
    script_version = ScriptVersion.includes(:script).where(script_id:)
    if params[:version]
      script_version = script_version.find(version_id)
    else
      script_version = script_version.references(:script_versions).order('script_versions.id DESC').first
      raise ActiveRecord::RecordNotFound if script_version.nil?
    end
    return [script_version.script, script_version]
  end

  def load_minimal_script_info(script_id, script_version_id)
    # Bypass ActiveRecord for performance
    sql = if script_version_id > 0
            <<~SQL.squish
              SELECT
                scripts.language,
                delete_type,
                scripts.replaced_by_script_id,
                script_codes.code,
                script_versions.created_at
              FROM scripts
              JOIN script_versions on script_versions.script_id = scripts.id
              JOIN script_codes on script_versions.rewritten_script_code_id = script_codes.id
              WHERE
                scripts.id = #{Script.connection.quote(script_id)}
                AND script_versions.id = #{Script.connection.quote(script_version_id)}
              LIMIT 1
            SQL
          else
            <<~SQL.squish
              SELECT
                scripts.language,
                delete_type,
                scripts.replaced_by_script_id,
                script_codes.code,
                scripts.code_updated_at
              FROM scripts
              JOIN script_versions on script_versions.script_id = scripts.id
              JOIN script_codes on script_versions.rewritten_script_code_id = script_codes.id
              WHERE
                scripts.id = #{Script.connection.quote(script_id)}
              ORDER BY script_versions.id DESC
              LIMIT 1
            SQL
          end
    script_info = Script.connection.select_one(sql)

    raise ActiveRecord::RecordNotFound if script_info.nil?

    Struct.new(:language, :delete_type, :replaced_by_script_id, :code, :code_updated_at).new(*script_info.values)
  end

  def handle_meta_request(language)
    unless update_host?
      script = Script.find(params[:id].to_i)
      redirect_to(script.code_url(sleazy: sleazy?, cn_greasy: cn_greasy?, format_override: (language == :css) ? 'meta.css' : 'meta.js', version_id: params[:version].presence), status: :moved_permanently, allow_other_host: true)
      return
    end

    is_css = language == :css
    script_id = params[:id].to_i
    script_version_id = (params[:version] || 0).to_i

    begin
      script_info = load_minimal_script_info(script_id, script_version_id)
    rescue ActiveRecord::RecordNotFound
      handle_code_not_found(script_id:)
      return
    end

    if script_info.replaced_by_script_id && script_info.delete_type == Script.delete_types[:redirect]
      redirect_to(Script.find(script_info.replaced_by_script_id).code_url(sleazy: sleazy?, cn_greasy: cn_greasy?, format_override: (language == :css) ? 'meta.css' : 'meta.js'), status: :moved_permanently, allow_other_host: true)
      return
    end

    unless script_info.delete_type.nil?
      handle_code_not_available
      return
    end

    # A style can serve out either JS or CSS. A script can only serve out JS.
    if script_info.language == 'js' && is_css
      handle_code_not_available
      return
    end

    script_info.code = CssToJsConverter.convert(script_info.code) if script_info.language == 'css' && !is_css

    parser = is_css ? CssParser : JsParser
    # Strip out some thing that could contain a lot of data (data: URIs).
    meta_js_code = parser.inject_meta(parser.get_meta_block(script_info.code), { icon: nil, resource: nil })

    cache_code_request(meta_js_code, script_id:, script_version_id_param: script_version_id, extension: is_css ? '.meta.css' : '.meta.js', code_updated_at: script_info.code_updated_at)

    headers['Last-Modified'] = script_info.code_updated_at.httpdate
    render body: meta_js_code, content_type: is_css ? 'text/css' : 'text/x-userscript-meta'
  end

  def set_bots_directive
    return unless @script

    if params[:version].present?
      @bots = 'noindex'
    elsif @script.unlisted?
      @bots = 'noindex,follow'
    end
  end

  # Keys are good for at least 5 minutes and at most 10 minutes after use.
  def install_keys
    now = Time.now.to_i
    present_key = now - (now % 300)
    past_key = present_key - 300
    Rails.cache.fetch_multi("install-key-#{present_key}", "install-key-#{past_key}", expires_in: 15.minutes) { SecureRandom.hex(10) }.values
  end
  helper_method :install_keys

  def provision_session_install_key(script)
    session[PingRequestChecking::SessionInstallKey::SESSION_KEY] ||= []
    session[PingRequestChecking::SessionInstallKey::SESSION_KEY] = session[PingRequestChecking::SessionInstallKey::SESSION_KEY].last(10)
    session[PingRequestChecking::SessionInstallKey::SESSION_KEY] << script.id unless session[PingRequestChecking::SessionInstallKey::SESSION_KEY].include?(script.id)
  end

  def show_integrity_hash_warning
    return unless current_user && @script.user_ids.include?(current_user.id)

    bih = @script.bad_integrity_hashes
    return unless bih.any?

    flash.now[:alert] ||= t('scripts.integrity_hashes.script_notice.text_html', detail: bih.map { |b| t('scripts.integrity_hashes.script_notice.detail', url: b[:url], expected_hash: b[:expected_hash], last_checked_at: view_context.markup_date(b[:last_success_at])) }.join(', ').html_safe, count: bih.count)
  end
end
