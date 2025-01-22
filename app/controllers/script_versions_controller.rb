class ScriptVersionsController < ApplicationController
  include ScriptAndVersions
  include UserTextHelper
  include PageCache

  before_action :authenticate_user!, except: [:index]
  before_action :authorize_by_script_id, except: [:index, :delete, :do_delete]
  before_action :check_for_deleted_by_script_id
  before_action :authorize_for_moderators_only, only: [:delete, :do_delete]
  before_action :check_read_only_mode, except: :index
  before_action :check_ip, only: :create
  before_action :handle_api_request, only: :index

  layout 'scripts', only: [:index]

  def index
    cachable_request = generally_cachable? && request.query_parameters.empty?
    page_key = "script/versions/#{params[:script_id]}/#{request_locale.id}" if cachable_request

    cache_page(page_key) do
      @script, @script_version = versionned_script(params[:script_id], params[:version])
      return if handle_publicly_deleted(@script)
      return if redirect_to_slug(@script, :script_id)

      @script_versions = @script.script_versions.order(id: :desc)

      unless params[:show_all_versions] == '1'
        version_ids_to_show = []
        @script_versions.each_with_index do |sv, i|
          version_ids_to_show << sv.id if (i + 1 >= @script_versions.length) || sv.rewritten_script_code_id != @script_versions[i + 1].rewritten_script_code_id
        end
        @script_versions = @script_versions.where(id: version_ids_to_show)
      end

      if params[:list_all] == '1'
        @paginate = false
      else
        @script_versions = @script_versions.paginate(page: page_number, per_page:)
      end

      respond_to do |format|
        format.html do
          if params[:show_all_versions].present? || params[:version].present? || params[:page].present?
            @bots = 'noindex'
          elsif @script.unlisted?
            @bots = 'noindex,follow'
          end
          @canonical_params = [:script_id, :version, :show_all_versions]
          @link_alternates = [
            { url: current_api_url_with_params(format: :json), type: 'application/json' },
            { url: current_api_url_with_params(format: :jsonp, callback: 'callback'), type: 'application/javascript' },
          ]
          render_to_string
        end
        format.json do
          render json: @script_versions.map { |sv| { version: sv.version, created_at: sv.created_at, url: script_url(id: @script, version: sv.id), code_url: sv.code_url } }
        end
        format.jsonp do
          render json: @script_versions.map { |sv| { version: sv.version, created_at: sv.created_at, url: script_url(id: @script, version: sv.id), code_url: sv.code_url } }, callback: clean_json_callback_param
        end
      end
    end
  end

  def new
    @bots = 'noindex'

    if current_user.scripts.none? && session[:new_script_notice].nil?
      render 'new_script_notice'
      return
    end

    @script_version = ScriptVersion.new(changelog_markup: current_user.preferred_markup)

    if params[:script_id].nil?
      @script = Script.new(script_type: :public, language: params[:language] || 'js')
      @script.authors.build(user: current_user)
      @script_version.script = @script
      ensure_default_additional_info(@script_version, current_user.preferred_markup)
      @current_attachments = []
    else
      @script = Script.find(params[:script_id])
      @script_version.script = @script
      previous_script = @script.script_versions.last
      @script_version.code = previous_script.code
      previous_script.localized_attributes.each { |la| @script_version.build_localized_attribute(la) }
      ensure_default_additional_info(@script_version, current_user.preferred_markup)
      @script_version.not_js_convertible_override = @script.not_js_convertible_override
      @current_attachments = previous_script.attachments
    end

    if @script.new_record?
      case UserRestrictionService.new(current_user).new_script_restriction
      when nil
        # OK
      when UserRestrictionService::NEEDS_CONFIRMATION, UserRestrictionService::BLOCKED
        render 'must_confirm'
        return
      when UserRestrictionService::NEEDS_SECURE_LOGIN
        render 'needs_secure_login'
        return
      when UserRestrictionService::RATE_LIMITED
        render 'rate_limited'
        return
      when UserRestrictionService::DELAYED
        render 'delayed'
        return
      else
        raise "Unknown restriction #{UserRestrictionService.new(current_user).new_script_restriction}"
      end

      unless EmailCheckingService.check_user(current_user)
        render 'disposable_email'
        return
      end
    end

    render layout: 'scripts' unless @script.new_record?
  end

  def confirm_new_author
    session[:new_script_notice] = true
    redirect_to new_script_version_path(language: params[:language])
  end

  def create
    @bots = 'noindex'
    preview = params[:preview].present?

    # We will not purge these as they can be used by prior versions.
    svp = script_version_params
    svp['attachments'] = svp['attachments'].reject { |signed_id| params["remove-attachment-#{signed_id}"] == '1' }

    @script_version = ScriptVersion.new
    @script_version.assign_attributes(svp)

    if params[:script_id].nil?
      @script = Script.new(language: params[:language] || 'js')
      @script.authors.build(user: current_user)
    else
      @script = Script.find(params[:script_id])
    end

    @script_version.script = @script
    @script.script_type = params['script']['script_type'].to_i
    @script.locale_id = params['script']['locale_id'] if params['script'].key?('locale_id')

    if !@script.sensitive? && (params['script']['adult_content_self_report'] == '1' || sleazy?)
      @script.marked_adult_by_user = current_user
      @script.adult_content_self_report = true
    end

    @script.not_adult_content_self_report_date = Time.current if @script.sensitive? && params['script']['not_adult_content_self_report'] == '1'

    save_record = !preview && params['add-additional-info'].nil?

    if save_record && @script.new_record?
      # Check for restrictions. At this point, any restriction will just an error page as they should have seen the
      # nice error on the new page already.
      unless UserRestrictionService.new(current_user).new_script_restriction.nil?
        @script.errors.add :base, 'You cannot currently post a script.'
        return
      end

      unless EmailCheckingService.check_user(current_user)
        @script.errors.add :base, 'You cannot currently post a script.'
        return
      end
    end

    # Additional info - if we're saving, don't construct blank ones
    @script_version.localized_attributes(&:mark_for_destruction)
    params['script_version']['additional_info']&.each do |_index, additional_info_params|
      locale_id = additional_info_params['locale'] || @script.locale_id
      attribute_value = additional_info_params['attribute_value']
      attribute_default = additional_info_params['attribute_default'] == 'true'
      value_markup = additional_info_params['value_markup']
      additional_info_la = @script_version.localized_attributes.build({ attribute_key: 'additional_info', attribute_value:, attribute_default:, locale_id:, value_markup: }) unless save_record && attribute_value.blank?
      additional_info_la&.construct_mentions(detect_possible_mentions(additional_info_la.attribute_value, additional_info_la.value_markup))
    end

    unless params[:code_upload].nil?
      uploaded_content = params[:code_upload].read
      unless uploaded_content.force_encoding('UTF-8').valid_encoding?
        @script_version.script.errors.add(:code, I18n.t('errors.messages.script_update_not_utf8'))

        # Unfortunately, we can't retain what the user picked for screenshots
        nssv = @script.newest_saved_script_version
        @current_attachments = nssv&.attachments || []

        render :new
        return
      end
      @script_version.code = uploaded_content
    end

    if @script.library?
      # accept name and description as params for libraries, as they may not have meta blocks
      @script.delete_localized_attributes('name')
      @script.localized_attributes.build({ attribute_key: 'name', attribute_value: params[:name], attribute_default: true, locale: @script.locale, value_markup: 'text' }) unless params[:name].nil?
      @script.delete_localized_attributes('description')
      @script.localized_attributes.build({ attribute_key: 'description', attribute_value: params[:description], attribute_default: true, locale: @script.locale, value_markup: 'text' }) unless params[:description].nil?

      # automatically add a version for libraries, if missing
      @script_version.add_missing_version = true
    end

    # if the script is (being) deleted, don't require a description
    if @script.deleted? && @script.description.nil?
      @script.delete_localized_attributes('description')
      @script.localized_attributes.build({ attribute_key: 'description', attribute_value: 'Deleted', attribute_default: true, locale: @script.locale, value_markup: 'text' })
    end

    @script_version.calculate_all(@script.description)
    @script.apply_from_script_version(@script_version)

    script_check_results, script_check_result_code = ScriptCheckingService.check(@script_version)

    # support preview for JS disabled users
    @preview = view_context.format_user_text(@script_version.additional_info, @script_version.additional_info_markup) if preview

    @script_version.localized_attributes.build({ attribute_key: 'additional_info', attribute_default: false }) unless params['add-additional-info'].nil?

    recaptcha_ok = !@script.new_record? || (UserRestrictionService.new(current_user).must_recaptcha? ? verify_recaptcha : true)

    # Don't save if this is a preview or if there's something invalid.
    # If we're attempting to save, ensure all validations are run - short circuit the OR.
    if !save_record || !recaptcha_ok || (!@script.valid? | !@script_version.valid?) || script_check_result_code == ScriptChecking::Result::RESULT_CODE_BLOCK
      @script.errors.add(:base, script_check_results.first.public_reason) if script_check_result_code == ScriptChecking::Result::RESULT_CODE_BLOCK

      # Unfortunately, we can't retain what the user picked for screenshots
      nssv = @script.newest_saved_script_version
      @current_attachments = nssv&.attachments || []

      ensure_default_additional_info(@script_version, current_user.preferred_markup)

      if @script.new_record?
        # This is a pointless message
        @script_version.errors.delete(:rewritten_script_code)
        render :new
      else
        # get the original script for display within the scripts layout
        @script.reload
        # but retain the script type!
        @script.script_type = params['script']['script_type'].to_i
        render :new, layout: 'scripts'
      end
      return
    end

    @script.review_state = 'required' if script_check_result_code == ScriptChecking::Result::RESULT_CODE_REVIEW && @script.review_state != 'approved'

    @script.script_versions << @script_version
    @script_version.save!
    @script.save!

    if script_check_result_code == ScriptChecking::Result::RESULT_CODE_BAN
      if Rails.env.test?
        ScriptCheckerBanAndDeleteJob.perform_now(@script.id, script_check_results.to_json)
      else
        ScriptCheckerBanAndDeleteJob.set(wait: rand(1..10).minutes).perform_later(@script.id, script_check_results.to_json)
      end
    elsif params[:script_id].nil?
      # Disabled due to poor results
      # AkismetScriptCheckingJob.perform_later(@script, request.ip, request.user_agent, request.referer)
    end

    redirect_to @script
  end

  def additional_info_form
    render partial: 'additional_info', locals: { la: LocalizedScriptVersionAttribute.new({ attribute_default: false, value_markup: current_user.preferred_markup }), index: params[:index].to_i }
  end

  def delete
    @script_version = ScriptVersion.find(params[:script_version_id])
    @script = @script_version.script
    @bots = 'noindex'
  end

  def do_delete
    # Grab those vars...
    delete

    if @script_version.script.script_versions.count == 1
      @script_version.errors.add(:script, 'would have no versions')
      render :delete
      return
    end

    ma = ModeratorAction.new
    ma.moderator = current_user
    ma.script = @script
    ma.action = "Delete version #{@script_version.version}, ID #{@script_version.id}"
    ma.reason = params[:reason]
    ma.save!

    @script_version.destroy
    # That might have been the latest version, recalculate
    @script.apply_from_script_version(@script.newest_saved_script_version)
    @script.save!

    flash[:notice] = 'Version deleted.' # rubocop:disable Rails/I18nLocaleTexts

    redirect_to @script
  end

  private

  def script_version_params
    params
      .require(:script_version)
      .permit(:code, :changelog, :changelog_markup, :version_check_override, :add_missing_version, :namespace_check_override,
              :add_missing_namespace, :minified_confirmation, :sensitive_site_confirmation, :license_missing_override,
              :not_js_convertible_override, :allow_code_previously_posted, :meta_not_at_start_confirmation, attachments: [])
  end

  def check_for_deleted_by_script_id
    return if params[:script_id].nil?

    handle_publicly_deleted(Script.find_by(id: params[:script_id]))
  end
end
