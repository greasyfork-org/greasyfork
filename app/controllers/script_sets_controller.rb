class ScriptSetsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_by_user_id
  before_action :ensure_set_ownership, except: [:new, :create, :add_to_set, :index]
  before_action :check_read_only_mode
  before_action :check_ip, only: :create

  def index
    render json: current_user.script_sets.map { |ss|
      {
        id: ss.id,
        name: ss.name,
        scripts: ss.scripts(script_subset, as_ids: true),
      }
    }
  end

  def new
    @user = User.find(params[:user_id])
    @set = ScriptSet.new
    @set.user = @user
    @set.favorite = !params[:fav].nil?
    @set.add_child(Script.find(params[:script_id]), exclusion: false) unless params[:script_id].nil?
    @child_set_user = @user
  end

  def edit
    @set = ScriptSet.find(params[:id])
    @user = User.find(params[:user_id])
    @child_set_user = @user
  end

  def create
    @set = ScriptSet.new
    @set.user = User.find(params[:user_id])
    if params[:favorite] == '1'
      # check to make sure the user doesn't already have a favorite set
      unless @set.user.favorite_script_set.nil?
        @child_set_user = @set.user
        render action: :new
        return
      end
      make_favorite_set(@set)
    end
    return if handle_update(@set)

    render action: :new
  end

  def update
    @set = ScriptSet.find(params[:id])

    # blow away everything, the form will resubmit the info
    @set.set_inclusions.each(&:mark_for_destruction)
    @set.automatic_set_inclusions.each(&:mark_for_destruction)
    @set.script_inclusions.each(&:mark_for_destruction)

    return if handle_update(@set)

    render action: :edit
  end

  def destroy
    set = ScriptSet.find(params[:id])
    ScriptSetSetInclusion.where(child_id: set.id).destroy_all
    set.destroy
    redirect_to set.user
  end

  private

  def handle_update(set)
    set.assign_attributes(script_set_params) unless set.favorite

    @child_set_user = nil
    @child_set_user = User.find(params['child-set-user-id']) unless params['child-set-user-id'].nil?
    errors = []

    # Previously added scripts
    params['scripts-included']&.each do |script_id|
      next if (params['remove-selected-scripts'] == 'i') && !params['remove-scripts-included'].nil? && params['remove-scripts-included'].include?(script_id)

      set.add_child(Script.find(script_id), exclusion: false)
    end
    params['scripts-excluded']&.each do |script_id|
      next if (params['remove-selected-scripts'] == 'e') && !params['remove-scripts-excluded'].nil? && params['remove-scripts-excluded'].include?(script_id)

      set.add_child(Script.find(script_id), exclusion: true)
    end

    # Previously added sets
    params['sets-included']&.each do |set_id|
      next if (params['remove-selected-sets'] == 'i') && !params['remove-sets-included'].nil? && params['remove-sets-included'].include?(set_id)

      set.add_child(ScriptSet.find(set_id), exclusion: false)
    end
    params['sets-excluded']&.each do |set_id|
      next if (params['remove-selected-sets'] == 'e') && !params['remove-sets-excluded'].nil? && params['remove-sets-excluded'].include?(set_id)

      set.add_child(ScriptSet.find(set_id), exclusion: true)
    end

    # Previously added automatic sets
    params['automatic-sets-included']&.each do |set_id|
      next if (params['remove-selected-automatic-sets'] == 'i') && !params['remove-automatic-sets-included'].nil? && params['remove-automatic-sets-included'].include?(set_id)

      ssasi = ScriptSetAutomaticSetInclusion.from_param_value(set_id, exclusion: false)
      set.add_automatic_child(ssasi)
    end
    params['automatic-sets-excluded']&.each do |set_id|
      next if (params['remove-selected-automatic-sets'] == 'e') && !params['remove-automatic-sets-excluded'].nil? && params['remove-automatic-sets-excluded'].include?(set_id)

      ssasi = ScriptSetAutomaticSetInclusion.from_param_value(set_id, exclusion: true)
      set.add_automatic_child(ssasi)
    end

    # Add script
    if !params['script-action'].nil? && !params['add-script'].nil?
      params['add-script'].split(/\s+/).each do |possible_script|
        script_id = nil
        # is it an ID?
        begin
          script_id = Integer(possible_script)
        rescue ArgumentError, TypeError
        end

        # is it a URL?
        if script_id.nil?
          begin
            path_params = Rails.application.routes.recognize_path(possible_script)
            script_id = path_params[:id]
          rescue ActionController::RoutingError
          end
        end

        if script_id.nil?
          errors << I18n.t('script_sets.could_not_parse_script', value: possible_script)
        else
          script = Script.find(script_id)
          errors << I18n.t('script_sets.already_included', name: script.name(request_locale)) unless set.add_child(script, exclusion: params['script-action'] == 'e')
        end
      end
    end

    # Add set
    if !params['set-action'].nil? && !params['add-child-set'].nil?
      child_set = ScriptSet.find(params['add-child-set'])
      errors << I18n.t('script_sets.already_included', name: child_set.name) unless set.add_child(child_set, exclusion: params['set-action'] == 'e')
    end

    # Add automatic set
    if !params['add-automatic-script-set-1'].nil?
      ssasi = ScriptSetAutomaticSetInclusion.from_param_value('1-', exclusion: false)
      i18n_key, i18n_params = ssasi.i18n_params
      errors << I18n.t('script_sets.already_included', name: I18n.t(i18n_key, **i18n_params)) unless set.add_automatic_child(ssasi)
    elsif !params['add-automatic-script-set-2'].nil?
      ssasi = ScriptSetAutomaticSetInclusion.from_param_value("2-#{params['add-automatic-script-set-value-2']}", exclusion: params['add-automatic-script-set-2'] == 'e')
      i18n_key, i18n_params = ssasi.i18n_params
      errors << I18n.t('script_sets.already_included', name: I18n.t(i18n_key, **i18n_params)) unless set.add_automatic_child(ssasi)
    elsif !params['add-automatic-script-set-3'].nil? && !params['add-automatic-script-set-value-3'].nil? && !params['add-automatic-script-set-value-3'].empty?
      automatic_script_set_user = parse_user(params['add-automatic-script-set-value-3'])
      automatic_script_set_user = automatic_script_set_user&.id
      ssasi = ScriptSetAutomaticSetInclusion.from_param_value("3-#{automatic_script_set_user}", exclusion: params['add-automatic-script-set-3'] == 'e')
      i18n_key, i18n_params = ssasi.i18n_params
      errors << I18n.t('script_sets.already_included', name: I18n.t(i18n_key, **i18n_params)) unless set.add_automatic_child(ssasi)
    elsif !params['add-automatic-script-set-4'].nil?
      params['add-automatic-script-set-value-4'].each do |l|
        ssasi = ScriptSetAutomaticSetInclusion.from_param_value("4-#{l}", exclusion: params['add-automatic-script-set-4'] == 'e')
        i18n_key, i18n_params = ssasi.i18n_params
        errors << I18n.t('script_sets.already_included', name: I18n.t(i18n_key, **i18n_params)) unless set.add_automatic_child(ssasi)
      end
    end

    # Change the user for whom we're listing the sets
    if !params['child-set-user-refresh'].nil? && !@child_set_user.nil?
      @child_set_user = parse_user(params['child-set-user'])

      if @child_set_user.nil?
        @child_set_user = current_user
        errors << "Could not parse user '#{CGI.escapeHTML(params['child-set-user'])}'"
      end
    end

    set.valid? if params[:save] == '1'

    errors.each do |err|
      set.errors.add(:base, err)
    end

    recaptcha_ok = current_user.needs_to_recaptcha? ? verify_recaptcha : true
    new_set = set.new_record?

    # Require recaptcha for creating non-favourite new sets
    if set.errors.empty? && params[:save] == '1' && (!new_set || set.favorite || recaptcha_ok)
      set.save!
      redirect_to set.user
      flash[:notice] = I18n.t('script_sets.saved')
      if new_set
        blocked_script_text = BlockedScriptText.bannable.find { |bst| set.name.include?(bst.text) || set.description.include?(bst.text) }
        UserBanAndDeleteJob.set(wait: 5.minutes).perform_later(set.user.id, blocked_script_text.private_reason, blocked_script_text.public_reason) if blocked_script_text
      end
      return true
    end

    return false
  end

  def parse_user(value)
    # is it an ID?
    begin
      return User.find(Integer(value))
    rescue ArgumentError, TypeError
    end

    # is it a URL?
    begin
      path_params = Rails.application.routes.recognize_path(value)
      return User.find(path_params[:id]) if path_params.key?(:id)
    rescue ActionController::RoutingError
    end

    # is it a name?
    return User.find_by(name: value)
  end

  def script_set_params
    params.expect(script_set: [:name, :description, :default_sort])
  end

  def make_favorite_set(set)
    set.favorite = true
    # these are not displayed - they are just placeholders
    set.name = 'Favorite'
    set.description = 'Favorite scripts'
  end

  def ensure_set_ownership
    set = ScriptSet.find(params[:id])
    user = User.find(params[:user_id])
    render_404('Script set does not exist') if set.user != user
  end
end
