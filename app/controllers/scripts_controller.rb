require 'script_importer/script_syncer'
require 'csv'
require 'fileutils'
require 'cgi'
require 'css_to_js_converter'
require 'css_parser'
require 'js_parser'
require 'digest'

class ScriptsController < ApplicationController
  include ScriptAndVersions

  MEMBER_AUTHOR_ACTIONS = [:sync_update, :update_promoted, :request_permanent_deletion, :unrequest_permanent_deletion, :update_promoted, :invite, :remove_author].freeze
  MEMBER_AUTHOR_OR_MODERATOR_ACTIONS = [:delete, :do_delete, :undelete, :do_undelete, :derivatives, :admin, :update_locale, :request_duplicate_check].freeze
  MEMBER_MODERATOR_ACTIONS = [:mark, :do_mark, :do_permanent_deletion, :reject_permanent_deletion, :approve].freeze
  MEMBER_PUBLIC_ACTIONS = [:diff, :report, :accept_invitation].freeze
  MEMBER_PUBLIC_ACTIONS_WITH_SPECIAL_LOADING = [:show, :show_code, :user_js, :meta_js, :user_css, :meta_css, :feedback, :install_ping, :stats, :sync_additional_info_form].freeze

  before_action do
    case action_name.to_sym
    when *MEMBER_AUTHOR_ACTIONS
      @script = Script.find(params[:id])
      render_access_denied unless @script.users.include?(current_user)
      render_locked if @script.locked?
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

  skip_before_action :verify_authenticity_token, only: [:install_ping, :user_js, :meta_js, :user_css, :meta_css, :show, :show_code]

  # The value a syncing additional info will have after syncing is added but before the first sync succeeds
  ADDITIONAL_INFO_SYNC_PLACEHOLDER = '(Awaiting sync)'.freeze

  include ScriptListings

  def show
    @script, @script_version = versionned_script(params[:id], params[:version])

    return if handle_publicly_deleted(@script)

    respond_to do |format|
      format.html do
        return if handle_wrong_url(@script, :id)

        @by_sites = TopSitesService.get_by_sites(script_subset: script_subset)
        @link_alternates = [
          { url: current_path_with_params(format: :json), type: 'application/json' },
          { url: current_path_with_params(format: :jsonp, callback: 'callback'), type: 'application/javascript' },
        ]
        @canonical_params = [:id, :version]
        set_bots_directive
        @ad_method = choose_ad_method_for_script(@script)
      end
      format.js do
        redirect_to @script.code_url
      end
      format.json { render json: @script.as_json(include: :users) }
      format.jsonp { render json: @script.as_json(include: :users), callback: clean_json_callback_param }
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
        @code = @script_version.rewritten_code
        set_bots_directive
        @canonical_params = [:id, :version]
        @show_ad = eligible_for_ads?(@script)
      end
      format.js do
        redirect_to @script.code_url
      end
      format.user_script_meta do
        route_params = { id: params[:id], name: @script.name, format: nil }
        route_params[:version] = params[:version] unless params[:version].nil?
        redirect_to meta_js_script_path(route_params)
      end
    end
  end

  def feedback
    @script, @script_version = versionned_script(params[:id], params[:version])

    return if handle_publicly_deleted(@script)

    return if handle_wrong_url(@script, :id)

    @discussions = @script.discussions
                          .visible
                          .where(report_id: nil)
                          .includes(:stat_first_comment, :poster)
                          .order(stat_last_reply_date: :desc)
                          .paginate(page: params[:page], per_page: 25)
    @discussion = @discussions.build(discussion_category: DiscussionCategory.script_discussions)
    @discussion.comments.build(text_markup: current_user&.preferred_markup)

    @subscribe = current_user&.subscribe_on_discussion

    set_bots_directive
    @canonical_params = [:id, :version]
  end

  def user_js
    respond_to do |format|
      format.any(:html, :all, :js) do
        script_id = params[:id].to_i
        script_version_id = params[:version].to_i

        script, script_version = minimal_versionned_script(script_id, script_version_id)
        return if handle_replaced_script(script)

        user_js_code = if script.deleted_and_blanked?
                         script_version.generate_blanked_code
                       elsif script.css?
                         unless script.css_convertible_to_js?
                           head :not_found
                           return
                         end
                         CssToJsConverter.convert(script_version.rewritten_code)
                       else
                         script_version.rewritten_code
                       end

        # If the request specifies a specific version, the code will never change, so inform the manager not to check for updates.
        user_js_code = script_version.parser_class.inject_meta(user_js_code, downloadURL: 'none') if params[:version].present? && !script.library?

        # Only cache if:
        # - It's not for a specific version (as the caching does not work with query params)
        # - It's a .user.js extension (client's Accept header may not match path).
        cache_request(user_js_code) if script_version_id == 0 && request.fullpath.end_with?('.user.js')

        render body: user_js_code, content_type: 'text/javascript'
      end
      format.user_script_meta do
        meta_js
      end
    end
  end

  def user_css
    respond_to do |format|
      format.any(:html, :all, :css) do
        script_id = params[:id].to_i
        script_version_id = params[:version].to_i

        script, script_version = minimal_versionned_script(script_id, script_version_id)
        return if handle_replaced_script(script)

        user_js_code = script.script_delete_type_id == 2 ? script_version.generate_blanked_code : script_version.rewritten_code

        # If the request specifies a specific version, the code will never change, so inform the manager not to check for updates.
        user_js_code = script_version.parser_class.inject_meta(user_js_code, downloadURL: 'none') if params[:version].present? && !script.library?

        # Only cache if:
        # - It's not for a specific version (as the caching does not work with query params)
        # - It's a .user.css extension (client's Accept header may not match path).
        cache_request(user_js_code) if script_version_id == 0 && request.fullpath.end_with?('.user.css')

        render body: user_js_code, content_type: 'text/css'
      end
    end
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
      head :unprocessable_entity
      return
    end
    ip, script_id = ScriptsController.per_user_stat_params(request, params)
    if ip.nil? || script_id.nil?
      head :unprocessable_entity
      return
    end

    if install_keys.any? { |install_key| Digest::SHA1.hexdigest(request.remote_ip + script_id + install_key) == params[:ping_key] }
      passed_checks = PingRequestCheckingService.check(request)
      if passed_checks.count >= 2
        ip = Array.new(4) { rand(256) }.join('.') unless Rails.application.config.ip_address_tracking
        Rails.logger.warn("Recorded for script #{script_id} and IP #{ip} - passed ping checks: #{passed_checks.join(', ')}")
        Script.record_install(script_id, ip)
      else
        Rails.logger.warn("Not recorded for script #{script_id} and IP #{ip} - only passed ping checks: #{passed_checks.join(', ')}")
      end
    end

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
    @show_ad = eligible_for_ads?(@script)
  end

  def sync_update
    unless params['stop-syncing'].nil?
      @script.script_sync_type_id = nil
      @script.last_attempted_sync_date = nil
      @script.last_successful_sync_date = nil
      @script.sync_identifier = nil
      @script.sync_error = nil
      @script.localized_attributes_for('additional_info').each do |la|
        la.sync_identifier = nil
      end
      @script.save(validate: false)
      flash[:notice] = 'Script sync turned off.'
      redirect_to @script
      return
    end

    @script.assign_attributes(params.require(:script).permit(:script_sync_type_id, :sync_identifier))

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
          @script.localized_attributes.build(attribute_key: 'additional_info', sync_identifier: sync_params['sync_identifier'], value_markup: sync_params['value_markup'], locale_id: attribute_default ? @script.locale_id : sync_params['locale'], attribute_value: ADDITIONAL_INFO_SYNC_PLACEHOLDER, attribute_default: attribute_default)
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
      rescue ArgumentError => e
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
        flash[:notice] = 'Script successfully synced.'
      when :unchanged
        flash[:notice] = 'Script successfully synced, but no changes found.'
      when :failure
        flash[:notice] = "Script sync failed - #{@script.sync_error}."
      end
    end
    redirect_to @script
  end

  def delete; end

  def do_delete
    # Handle replaced by
    replaced_by = get_script_from_input(params[:replaced_by_script_id])
    case replaced_by
    when :non_gf_url
      @script.errors.add(:replaced_by_script_id, I18n.t('errors.messages.must_be_greasy_fork_script', site_name: site_name))
      render :delete
      return
    when :non_script_url
      @script.errors.add(:replaced_by_script_id, :must_be_greasy_fork_script)
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
      ma.action = @script.locked ? 'Delete and lock' : 'Delete'
      ma.reason = params[:reason]
      @script.delete_reason = params[:reason]
      ma.save!
      @script.ban_all_authors!(moderator: current_user, reason: params[:reason]) if params[:banned]
    end
    @script.permanent_deletion_request_date = nil if @script.locked
    @script.script_delete_type_id = params[:script_delete_type_id]
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
      ma.action = 'Undelete'
      ma.reason = params[:reason]
      ma.save!
      @script.locked = false
      if params[:unbanned]
        @script.users.select(&:banned?).each do |user|
          ma_ban = ModeratorAction.new
          ma_ban.moderator = current_user
          ma_ban.user = user
          ma_ban.action = 'Unban'
          ma_ban.reason = params[:reason]
          ma_ban.save!
          user.banned_at = nil
          user.save!
        end
      end
    end
    @script.script_delete_type_id = nil
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
    @script.script_delete_type_id = ScriptDeleteType::KEEP
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

  def do_permanent_deletion
    Script.transaction do
      @script.destroy!
      ma = ModeratorAction.new
      ma.moderator = current_user
      ma.script = @script
      ma.action = 'Permanent deletion'
      ma.reason = 'Author request'
      ma.save!
    end
    flash[:notice] = I18n.t('scripts.delete_permanently_notice_immediate')
    redirect_to root_path
  end

  def reject_permanent_deletion
    Script.transaction do
      ma = ModeratorAction.new
      ma.moderator = current_user
      ma.script = @script
      ma.action = 'Permanent deletion denied'
      ma.reason = params[:reason]
      ma.save!
      @script.permanent_deletion_request_date = nil
      @script.save(validate: false)
    end
    flash[:notice] = 'Permanent deletion request rejected.'
    redirect_to script
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
      ma.action = 'Mark as adult content'
    when 'not_adult'
      @script.sensitive = false
      @script.not_adult_content_self_report_date = nil
      ma.action = 'Mark as not adult content'
    when 'clear_not_adult'
      @script.not_adult_content_self_report_date = nil
    else
      @text = "Can't do that!"
      render 'home/error', status: :not_acceptable, layout: 'application'
      return
    end

    ma.save! unless ma.action.nil?

    @script.save!
    flash[:notice] = 'Script updated.'
    redirect_to @script
  end

  def stats
    @script, @script_version = versionned_script(params[:id], params[:version])

    return if handle_publicly_deleted(@script)

    return if handle_wrong_url(@script, :id)

    @bots = 'noindex' unless params[:period].nil?

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
      stat[:update_checks] = d >= update_check_start_date ? (update_check_values[d] || 0) : nil
      @stats[d] = stat
    end
    respond_to do |format|
      format.html do
        @canonical_params = [:id, :version]
        set_bots_directive
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
        render json: @stats
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
      @diff = Diffy::Diff.new(@other_script.newest_saved_script_version.code, @script.newest_saved_script_version.code, include_plus_and_minus_in_html: true, include_diff_info: true, diff: diff_options).to_s(:html).html_safe
    else
      flash[:notice] = t('scripts.admin.compare_must_be_local_url', site_name: site_name)
    end
  end

  def update_promoted
    promoted_script = get_script_from_input(params[:promoted_script_id])
    case promoted_script
    when :non_gf_url
      @script.errors.add(:promoted_script_id, I18n.t('errors.messages.must_be_greasy_fork_script', site_name: site_name))
      render :admin
      return
    when :non_script_url
      @script.errors.add(:promoted_script_id, :must_be_greasy_fork_script)
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

    if promoted_script && @script.sensitive? != promoted_script.sensitive?
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
    update_params = params.require(:script).permit(:locale_id)
    if @script.update(update_params)
      unless @script.users.include?(current_user)
        ModeratorAction.create!(script: @script, moderator: current_user, action: 'Update locale', reason: "Changed to #{@script.locale.code}#{update_params[:locale_id].blank? ? ' (auto-detected)' : ''}")
      end
      flash[:notice] = I18n.t('scripts.updated')
      redirect_to admin_script_path(@script)
      return
    end

    render :admin
  end

  def invite
    user_url_match = %r{https://(?:greasyfork|sleazyfork)\.org/(?:[a-zA-Z\-]+/)?users/([0-9]+)}.match(params[:invited_user_url])

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
    if @script.authors.count < 2 || @script.authors.where(user: user).none?
      flash[:error] = t('scripts.remove_author.failure')
      return
    end

    @script.authors.find_by!(user: user).destroy!
    flash[:notice] = t('scripts.remove_author.success', user_name: user.name)
    redirect_to script_path(@script)
  end

  def approve
    @script.update!(review_state: 'approved')
    flash[:notice] = 'Marked as approved.'
    redirect_to clean_redirect_param(:return_to) || script_path(@script)
  end

  def request_duplicate_check
    ScriptDuplicateCheckerJob.set(queue: 'user_low').perform_later(@script.id) unless ScriptDuplicateCheckerJob.currently_queued_script_ids.include?(@script.id)
    flash[:notice] = 'Similarity check will be completed in a few minutes.'
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
    if !script.replaced_by_script_id.nil? && script.replaced_by_script && script.script_delete_type_id == 1
      redirect_to(user_js_script_path(script.replaced_by_script, name: script.replaced_by_script.url_name, locale_override: nil), status: :moved_permanently)
      return true
    end
    return false
  end

  def cache_request(response_body)
    # Cache dir + request path without leading slash. Ensure it's actually under the cache dir to prevent
    # directory traversal.
    cache_request_portion = CGI.unescape(request.fullpath[1..])
    cache_path = Rails.application.config.script_page_cache_directory.join(cache_request_portion).cleanpath
    return unless cache_path.to_s.start_with?(Rails.application.config.script_page_cache_directory.to_s)

    # Make sure each portion is under the filesystem limit
    return unless cache_path.to_s.split('/').all? { |portion| portion.bytesize <= 255 }

    FileUtils.mkdir_p(cache_path.parent)
    File.write(cache_path, response_body) unless File.exist?(cache_path)
    # nginx does not seem to automatically compress with try_files, so give it a .gz to use, but keep the original.
    system('gzip', '--keep', cache_path.to_s) unless File.exist?("#{cache_path}.gz")
  end

  def handle_wrong_url(resource, id_param_name)
    raise ActiveRecord::RecordNotFound if resource.nil?
    return true if handle_wrong_site(resource)
    return true if redirect_to_slug(resource, id_param_name)

    return false
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

  def load_minimal_script_info(script_id, script_version_id)
    # Bypass ActiveRecord for performance
    sql = if script_version_id > 0
            <<~SQL.squish
              SELECT
                scripts.language,
                script_delete_type_id,
                scripts.replaced_by_script_id,
                script_codes.code
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
                script_delete_type_id,
                scripts.replaced_by_script_id,
                script_codes.code
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

    Struct.new(:language, :script_delete_type_id, :replaced_by_script_id, :code).new(*script_info.values)
  end

  def handle_meta_request(language)
    is_css = language == :css
    script_id = params[:id].to_i
    script_version_id = (params[:version] || 0).to_i

    script_info = load_minimal_script_info(script_id, script_version_id)

    if !script_info.replaced_by_script_id.nil? && script_info.script_delete_type_id == ScriptDeleteType::KEEP
      redirect_to(id: script_info.replaced_by_script_id, status: :moved_permanently)
      return
    end

    # A style can serve out either JS or CSS. A script can only serve out JS.
    if script_info.language == 'js' && is_css
      head :not_found
      return
    end

    script_info.code = CssToJsConverter.convert(script_info.code) if script_info.language == 'css' && !is_css

    parser = is_css ? CssParser : JsParser
    # Strip out some thing that could contain a lot of data (data: URIs). get_blanked_code already does this.
    meta_js_code = script_info.script_delete_type_id == ScriptDeleteType::BLANKED ? ScriptVersion.generate_blanked_code(script_info.code, parser) : parser.inject_meta(parser.get_meta_block(script_info.code), { icon: nil, resource: nil })

    # Only cache if:
    # - It's not for a specific version (as the caching does not work with query params)
    # - It's a .meta.js extension (client's Accept header may not match path).
    cache_request(meta_js_code) if !is_css && script_version_id == 0 && request.fullpath.end_with?('.meta.js')

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
    [
      Rails.cache.fetch("install-key-#{present_key}", expires_in: 15.minutes) { SecureRandom.hex(10) },
      Rails.cache.fetch("install-key-#{past_key}", expires_in: 15.minutes) { SecureRandom.hex(10) },
    ]
  end
  helper_method :install_keys
end
