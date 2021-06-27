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
      if script.replaced_by_script_id
        # Same action, different script.
        if params.include?(:script_id)
          redirect_to script_id: script.replaced_by_script_id, status: :moved_permanently
        else
          redirect_to id: script.replaced_by_script_id, status: :moved_permanently
        end
        return true
      end
      render_deleted(script: script)
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
    current_script = Script.includes(users: {}, license: {}, localized_attributes: :locale, compatibilities: :browser, script_applies_tos: :site_application, antifeatures: :locale).find(script_id)
    return [current_script, current_script.newest_saved_script_version] if version_id.nil?

    version_id = version_id.to_i
    script_version = ScriptVersion.find(version_id)
    return nil if script_version.script_id != script_id

    script = Script.new

    # this is not versionned information
    script.script_type_id = current_script.script_type_id
    script.locale = current_script.locale

    current_script.localized_attributes.each { |la| script.build_localized_attribute(la) }

    script.apply_from_script_version(script_version)
    script.id = script_id
    script.updated_at = script_version.updated_at
    script.user_ids = script_version.script.user_ids
    script.created_at = current_script.created_at
    script.updated_at = script_version.updated_at
    script.set_default_name
    # this is not necessarily accurate, as the revision the user picked may not have involved a code update
    script.code_updated_at = script_version.updated_at
    return [script, script_version]
  end

  def render_deleted(script: nil, http_code: 404)
    respond_to do |format|
      format.html do
        if script && script.site_applications.where(blocked: true).none?
          with = sphinx_options_for_request
          with[:site_application_id] = script.site_applications.pluck(:id)

          locale = request_locale
          with[:locale] = locale.id if locale.scripts?(script_subset)

          @scripts = Script.search(
            params[:q],
            with: with,
            per_page: 5,
            order: 'daily_installs DESC',
            populate: true,
            sql: { include: [:script_type, { localized_attributes: :locale }, :users] }
          )
        end

        if @scripts&.any?
          @page_description = t('scripts.deleted_notice_with_related')
          @paginate = false
          @skip_search_options = true
          render 'scripts/index', layout: 'list', status: http_code
        else
          @text = t('scripts.deleted_notice')
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
