module ScriptAndVersions
  def handle_wrong_site(script)
    if !script.sensitive && sleazy?
      render_404 I18n.t('scripts.non_adult_content_on_sleazy')
      return true
    end
    if script.sensitive && script_subset == :greasyfork && script.users.exclude?(current_user)
      message = current_user.nil? ? view_context.it('scripts.adult_content_on_greasy_not_logged_in_error', login_link: new_user_session_path) : view_context.it('scripts.adult_content_on_greasy_logged_in_error', edit_account_link: edit_user_registration_path)
      render_404 message
      return true
    end
    return false
  end

  def handle_publicly_deleted(script)
    if script.nil?
      render_deleted(http_code: 410)
      return true
    end

    return false if current_user && (script.users.include?(current_user) || current_user.moderator?)

    if script.deleted?
      if script.pure_404
        render_deleted
        return true
      end

      if script.replaced_by_script_id
        # Same action, different script.
        if params.include?(:script_id)
          redirect_to script_id: script.replaced_by_script_id, status: :moved_permanently
        else
          redirect_to id: script.replaced_by_script_id, status: :moved_permanently
        end
        return true
      end
      render_deleted(script:)
      return true
    end

    if script.pending_report_by_trusted_reporter? && !(current_user && script.reports.where(reporter: current_user).any?)
      render_pending_report(script)
      return true
    end

    if script.review_required?
      render_review_required(script)
      return true
    end

    return false
  end

  def versionned_script(script_id, version_id)
    return nil if script_id.nil?

    script_id = script_id.to_i
    current_script = Script.with_includes_for_show.find(script_id)
    return [current_script, current_script.newest_saved_script_version] if version_id.nil?

    version_id = version_id.to_i
    script_version = ScriptVersion.find(version_id)
    return nil if script_version.script_id != script_id

    script = Script.new

    # this is not versionned information
    script.script_type = current_script.script_type
    script.locale = current_script.locale
    script.default_name = current_script.default_name
    script.sensitive = current_script.sensitive
    script.language = current_script.language
    script.css_convertible_to_js = current_script.css_convertible_to_js
    script.adsense_approved = current_script.adsense_approved

    current_script.localized_attributes.includes(:mentions).find_each { |la| script.build_localized_attribute(la) }

    script.apply_from_script_version(script_version)
    script.id = script_id
    script.updated_at = script_version.created_at
    script.user_ids = script_version.script.user_ids
    script.created_at = current_script.created_at
    script.updated_at = script_version.created_at

    # this is not necessarily accurate, as the revision the user picked may not have involved a code update
    script.code_updated_at = script_version.created_at
    return [script, script_version]
  end

  def render_deleted(script: nil, http_code: 404)
    respond_to do |format|
      format.html do
        locale = request_locale

        if script&.deletion_message
          @text = script&.deletion_message&.html_safe
          render 'home/error', status: http_code, layout: 'application'
          return
        end

        @scripts = script.similar_scripts(script_subset:, locale: request_locale.code) if script && script.site_applications.where(blocked: true).none?

        @ad_method = AdMethod.no_ad(:script_deleted)

        report = @script.reports.upheld.last if @script&.locked
        if @scripts&.any?
          @page_description = if report
                                It.it('scripts.deleted_notice_with_related_and_reason', report_link: report_path(report, locale: locale.code))
                              else
                                t('scripts.deleted_notice_with_related')
                              end
          @paginate = false
          @skip_search_options = true
          render 'scripts/index', layout: 'list', status: http_code
        else
          @text = if report
                    It.it('scripts.deleted_notice_with_reason', report_link: report_path(report, locale: locale.code))
                  else
                    t('scripts.deleted_notice')
                  end
          render 'home/error', status: http_code, layout: 'application'
        end
      end
      format.all do
        head http_code
      end
    end
  end

  def render_pending_report(script)
    respond_to do |format|
      format.html do
        @text = t('scripts.reported_notice', script_name: script.name(request_locale))
        render 'home/error', status: :not_found, layout: 'application'
      end
      format.all do
        head :not_found
      end
    end
  end

  def render_review_required(script)
    respond_to do |format|
      format.html do
        @text = t('scripts.reported_notice', script_name: script.name(request_locale))
        render 'home/error', status: :not_found, layout: 'application'
      end
      format.all do
        head :not_found
      end
    end
  end
end
