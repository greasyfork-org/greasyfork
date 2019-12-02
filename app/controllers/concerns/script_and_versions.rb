module ScriptAndVersions
  def handle_wrong_site(script)
    if !script.sensitive && sleazy?
      render_404 I18n.t('scripts.non_adult_content_on_sleazy')
      return true
    end
    if script.sensitive && script_subset == :greasyfork && !script.users.include?(current_user)
      message = current_user.nil? ? view_context.it('scripts.adult_content_on_greasy_not_logged_in_error', login_link: new_user_session_path): view_context.it('scripts.adult_content_on_greasy_logged_in_error', edit_account_link: edit_user_registration_path)
      render_404 message
      return true
    end
    return false
  end

  def handle_publicly_deleted(script)
    if script.nil?
      render_deleted
      return true
    end

    if script.locked && !(script.users.include?(current_user) || current_user&.moderator?)
      render_deleted
      return true
    end

    if script.pending_report_by_trusted_reporter? && !(current_user && (script.users.include?(current_user) || current_user.moderator? || script.script_reports.where(reporter: current_user).any?))
      render_pending_report(script)
      return true
    end

    return false
  end

  def versionned_script(script_id, version_id)
    return nil if script_id.nil?
    script_id = script_id.to_i
    current_script = Script.includes(users: {}, license: {}, localized_attributes: :locale, compatibilities: :browser).find(script_id)
    return [current_script, current_script.get_newest_saved_script_version] if version_id.nil?
    version_id = version_id.to_i
    script_version = ScriptVersion.find(version_id)
    return nil if script_version.script_id != script_id
    script = Script.new

    # this is not versionned information
    script.script_type_id = current_script.script_type_id
    script.locale = current_script.locale

    current_script.localized_attributes.each{|la| script.build_localized_attribute(la)}

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

  def render_deleted
    respond_to do |format|
      format.html {
        @text = t('scripts.deleted_notice')
        render 'home/error', status: 403, layout: 'application'
      }
      format.all {
        head 404
      }
    end
  end

  def render_pending_report(script)
    respond_to do |format|
      format.html {
        @text = t('scripts.reported_notice', script_name: @script.name(I18n.locale))
        render 'home/error', status: 404, layout: 'application'
      }
      format.all {
        head 404
      }
    end
  end

  def check_for_deleted(script)
    return if script.nil?
    if current_user.nil? || (!script.users.include?(current_user) && !current_user.moderator?)
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
end