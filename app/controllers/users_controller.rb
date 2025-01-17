require 'script_importer/script_syncer'
require 'uri'
require 'securerandom'

class UsersController < ApplicationController
  MAX_LIST_ENTRIES = 1000

  include Webhooks
  include BrowserCaching

  skip_before_action :verify_authenticity_token, only: [:webhook]

  before_action :authenticate_user!, except: [:show, :webhook, :index]
  before_action :authorize_for_moderators_only, only: [:ban, :do_ban, :unban, :do_unban, :mark_email_as_confirmed]
  before_action :check_read_only_mode, except: [:index, :show]
  before_action :disable_browser_caching!, only: [:edit_sign_in]
  before_action :handle_api_request, only: [:index, :show]

  def index
    with = {}

    with[:email_domain] = params[:email_domain] if current_user&.moderator? && params[:email_domain].present?

    case params[:banned]
    when '1'
      with[:banned] = true
    when '0'
      with[:banned] = false
    end

    case params[:author]
    when '1'
      with[:script_count] = { gte: 1 }
    when '0'
      with[:script_count] = 0
    end

    if current_user&.moderator? && params[:same_ip]
      other_user = User.find(params[:same_ip])
      with[:ip] = other_user.current_sign_in_ip
    end

    order = case params[:sort]
            when 'name'
              { name: :asc }
            when 'scripts'
              { script_count: :desc }
            when 'total_installs'
              { script_total_installs: :desc }
            when 'created_script'
              { script_last_created: :desc }
            when 'updated_script'
              { script_last_updated: :desc }
            when 'daily_installs'
              { script_daily_installs: :desc }
            when 'ratings'
              { script_ratings: :desc }
            when 'created'
              { created_at: :desc }
            else
              if params[:q].presence
                { _score: :desc }
              else
                { created_at: :desc }
              end
            end

    @users = User.search(
      params[:q].presence || '*',
      fields: [{ name: :word_middle }],
      where: with,
      order:,
      page: page_number,
      per_page: per_page(default: 100)
    )

    @user_script_counts = Script.listable(script_subset).joins(:authors).where(authors: { user_id: @users.map(&:id) }).group(:user_id).count

    respond_to do |format|
      format.html do
        @bots = 'noindex,follow' if !params[:sort].nil? || !params[:q].nil?
        @title = t('users.listing_title')
        @canonical_params = [:page, :per_page, :sort, :q]
        render layout: 'base'
      end
      format.json { render json: @users.results.as_json }
      format.jsonp { render json: @users.results.as_json, callback: clean_json_callback_param }
    end
  end

  def show
    @user = User.find(params[:id])

    return if redirect_to_slug(@user, :id)

    @same_user = !current_user.nil? && current_user.id == @user.id

    respond_to do |format|
      format.html do
        @by_sites = TopSitesService.get_top_by_sites(script_subset:, user_id: @user.id)

        @scripts = (@same_user || (!current_user.nil? && current_user.moderator?)) ? @user.scripts : @user.scripts.listable_including_libraries(script_subset)
        @scripts = @scripts.includes(:users, :localized_attributes)
        @user_has_scripts = !@scripts.empty?

        @libraries = @scripts.not_deleted.where(script_type: :library)
        @unlisted_scripts = @scripts.not_deleted.where(script_type: :unlisted)
        @deleted_scripts = @scripts.deleted
        @scripts = @scripts.not_deleted.where(script_type: :public)

        @scripts = ScriptsController.apply_filters(@scripts, params.reverse_merge(language: 'all'), script_subset).paginate(per_page: per_page(default: 50), page: page_number)
        @other_site_scripts = (script_subset == :sleazyfork) ? @user.scripts.listable(:greasyfork).count : 0

        @bots = 'noindex,follow' if [:per_page, :set, :site, :sort, :language].any? { |name| params[name].present? }

        @link_alternates = [
          { url: current_api_url_with_params(format: :json), type: 'application/json' },
          { url: current_api_url_with_params(format: :jsonp, callback: 'callback'), type: 'application/javascript' },
        ]
        @canonical_params = [:id, :page, :per_page, :set, :site, :sort, :language]

        if @same_user
          conversation_scope = @user.conversations.includes(:users, :stat_last_poster)
          @recent_conversations = conversation_scope.order(stat_last_message_date: :desc).where(stat_last_message_date: 1.month.ago..)
          @more_conversations = conversation_scope.count > @recent_conversations.count
          scripts_with_bad_hashes = @scripts.not_deleted.with_bad_integrity_hashes.load
          flash.now[:alert] ||= t('scripts.integrity_hashes.user_notice_html', script_links: scripts_with_bad_hashes.map { |script| view_context.render_script(script) }.join(', ').html_safe, count: scripts_with_bad_hashes.count) if scripts_with_bad_hashes.any?
        end

        @show_profile = !@user.banned? && UserRestrictionService.new(@user).allow_posting_profile?

        render layout: 'base'
      end
      format.json { render json: @user.api_as_json(with_private_scripts: @same_user) }
      format.jsonp { render json: @user.api_as_json(with_private_scripts: @same_user), callback: clean_json_callback_param }
    end
  end

  def webhook_info
    @user = current_user
    if request.post?
      @user.generate_webhook_secret
      @user.save!
    end
    @webhook_scripts = Script.not_deleted.joins(:authors).where(authors: { user_id: @user.id }).where('sync_identifier LIKE "https://github.com/%" OR sync_identifier LIKE "https://raw.githubusercontent.com/%" OR sync_identifier LIKE "https://bitbucket.org/%" OR sync_identifier LIKE "https://gitlab.com/%"')
  end

  def webhook
    user = User.find(params[:user_id])
    changelog_markup = 'text'
    changes, git_url = if request.headers['User-Agent'] == 'Bitbucket-Webhooks/2.0'
                         process_bitbucket_webhook(user)
                       elsif request.headers['X-Gitlab-Token'].present?
                         process_gitlab_webhook(user)
                       else
                         changelog_markup = 'markdown'
                         process_github_webhook(user)
                       end
    process_webhook_changes(changes, git_url, changelog_markup:) if changes
  end

  def edit_sign_in; end

  def update_password
    if current_user.encrypted_password && !current_user.valid_password?(params[:password])
      current_user.errors.add(:current_password, :invalid)
      current_user.reload
      render :edit_sign_in
      return
    end

    if params[:new_password].blank?
      current_user.errors.add(:new_password, :invalid)
      current_user.reload
      render :edit_sign_in
      return
    end

    current_user.password = params[:new_password]
    current_user.password_confirmation = params[:new_password_confirmation]

    unless current_user.save
      current_user.reload
      render :edit_sign_in
      return
    end

    # password changed, have to sign in again
    bypass_sign_in(current_user)

    if current_user.require_secure_login? && !current_user.otp_required_for_login
      enable_2fa
      render :enable_2fa
      return
    end

    flash[:notice] = t('users.password_updated')
    redirect_to user_path(current_user)
  end

  def remove_password
    if current_user.identities.empty?
      flash[:notice] = t('users.cant_remove_password')
      redirect_to user_edit_sign_in_path
      return
    end
    current_user.encrypted_password = nil
    current_user.save!
    # password changed, have to sign in again
    bypass_sign_in(current_user)
    flash[:notice] = t('users.password_removed')
    redirect_to clean_redirect_param(:return_to) || user_edit_sign_in_path
  end

  def update_identity
    current_user.identities.each do |id|
      next unless id.provider == params[:provider]

      flash[:notice] = t('users.external_sign_in_updated', provider: Identity.pretty_provider(id.provider))
      id.syncing = params[:syncing]
      id.save
    end
    redirect_to user_edit_sign_in_path
  end

  def delete_identity
    if (current_user.identities.size == 1) && current_user.encrypted_password.nil?
      flash[:notice] = t('users.cant_remove_sign_in', provider: Identity.pretty_provider(params[:provider]))
      redirect_to user_edit_sign_in_path
      return
    end
    current_user.identities.each do |id|
      if id.provider == params[:provider]
        flash[:notice] = t('users.external_sign_in_removed', provider: Identity.pretty_provider(id.provider))
        id.delete
      end
    end
    redirect_to user_edit_sign_in_path
  end

  def ban
    @user = User.find(params[:user_id])
  end

  def do_ban
    user = User.find(params[:user_id])
    user.ban!(moderator: current_user, reason: params[:reason]) unless user.banned?
    user.lock_all_scripts!(reason: params[:reason], moderator: current_user, delete_type: params[:delete_type]) if params[:delete_type].present?
    user.delete_all_comments!(by_user: user) if params[:delete_comments] == '1'
    flash[:notice] = "#{user.name} has been banned."
    redirect_to user
  end

  def unban
    @user = User.find(params[:user_id])
  end

  def do_unban
    user = User.find(params[:user_id])
    user.unban!(moderator: current_user, reason: params[:reason], undelete_scripts: params[:undelete_scripts] == '1')
    flash[:notice] = "#{user.name} has been unbanned."
    redirect_to user
  end

  def delete_info
    @user = current_user
    @bots = 'noindex'
  end

  def delete_start
    @user = current_user
    @user.delete_confirmation_key = SecureRandom.hex
    @user.delete_confirmation_expiry = 1.day.from_now
    @user.save(validate: false)
    UserMailer.delete_confirm(@user, site_name).deliver_later
    flash[:notice] = t('users.delete.confirmation_email_sent')
    redirect_to @user
  end

  def delete_confirm
    @user = current_user
    if params[:key].blank? || @user.delete_confirmation_key.blank? || params[:key] != @user.delete_confirmation_key
      @error = t('users.delete.confirmation.key_mismatch')
    elsif @user.delete_confirmation_expiry.nil? || DateTime.now > @user.delete_confirmation_expiry
      @error = t('users.delete.confirmation.request_expired')
    end
  end

  def delete_complete
    @user = current_user
    if params[:cancel].present?
      @user.update(delete_confirmation_key: nil, delete_confirmation_expiry: nil)
      flash[:notice] = t('users.delete.confirmation.cancelled')
    elsif params[:key].blank? || @user.delete_confirmation_key.blank? || params[:key] != @user.delete_confirmation_key
      flash[:alert] = t('users.delete.confirmation.key_mismatch')
    elsif @user.delete_confirmation_expiry.nil? || DateTime.now > @user.delete_confirmation_expiry
      flash[:alert] = t('users.delete.confirmation.request_expired')
    else
      @user.destroy!
      sign_out @user
      flash[:alert] = t('users.delete.confirmation.completed')
    end
    redirect_to root_path
  end

  def send_confirmation_email
    current_user.send_confirmation_instructions
    flash[:notice] = t('devise.confirmations.send_instructions')
    redirect_to user_path(current_user)
  end

  def mark_email_as_confirmed
    user = User.find(params[:id])
    user.confirm
    user.save
    # rubocop:disable Rails/I18nLocaleTexts
    redirect_to user_path(user), notice: 'Email marked as confirmed'
    # rubocop:enable Rails/I18nLocaleTexts
  end

  def dismiss_announcement
    current_user&.announcement_seen!(params[:key])
    respond_to do |format|
      format.html do
        redirect_to root_path
      end
      format.js do
        head :ok
      end
    end
  end

  NOTIFICATION_KEYS = [
    Notification::NOTIFICATION_TYPE_NEW_CONVERSATION,
    Notification::NOTIFICATION_TYPE_NEW_MESSAGE,
    Notification::NOTIFICATION_TYPE_REPORT_RESOLVED_REPORTER,
    Notification::NOTIFICATION_TYPE_REPORT_FILED_REPORTED,
    Notification::NOTIFICATION_TYPE_REPORT_RESOLVED_REPORTED,
    Notification::NOTIFICATION_TYPE_NEW_COMMENT,
    Notification::NOTIFICATION_TYPE_MENTION,
    Notification::NOTIFICATION_TYPE_CONSECUTIVE_BAD_RATINGS,
  ].freeze

  def notification_settings
    @user = current_user
    @notification_settings = {}
    NOTIFICATION_KEYS.each do |notification_key|
      @notification_settings[notification_key] = UserNotificationSetting.delivery_types_for_user(@user, notification_key)
    end
  end

  def update_notification_settings
    User.transaction do
      current_user.update!(params.require(:user).permit(:subscribe_on_discussion, :subscribe_on_comment, :subscribe_on_script_discussion, :subscribe_on_conversation_starter, :subscribe_on_conversation_receiver))
      NOTIFICATION_KEYS.each do |notification_key|
        UserNotificationSetting.update_delivery_types_for_user(current_user, notification_key, params.dig(:notification_settings, notification_key) || [])
      end
      current_user.discussion_subscriptions.destroy_all if params[:unsubscribe_all_discussions] == '1'
      current_user.conversation_subscriptions.destroy_all if params[:unsubscribe_all_conversations] == '1'
    end
    flash[:notice] = t('users.notifications.save_success')
    redirect_to user_path(current_user)
  end

  def unsubscribe_all
    current_user.unsubscribe_all!
    flash[:notice] = t('users.notifications.unsubscribe_all_success')
    redirect_to user_path(current_user)
  end

  def unsubscribe_email
    current_user.unsubscribe_email!
    flash[:notice] = t('users.notifications.unsubscribe_email_success')
    redirect_to user_path(current_user)
  end

  def enable_2fa
    @return_to = params[:return_to]
    current_user.otp_secret = User.generate_otp_secret
    current_user.save!
  end

  def disable_2fa
    unless current_user.otp_required_for_login
      flash[:alert] = t('users.2fa_disabled_already')
      redirect_to user_edit_sign_in_path
      return
    end

    current_user.otp_required_for_login = false
    current_user.otp_secret = nil
    current_user.save!
    flash[:notice] = t('users.2fa_disabled')
    redirect_to user_edit_sign_in_path
  end

  def confirm_2fa
    unless current_user.validate_and_consume_otp!(params[:code])
      flash[:alert] = t('users.2fa_enable_code_incorrect')
      @return_to = params[:return_to]
      render :enable_2fa
      return
    end

    current_user.otp_required_for_login = true
    current_user.save!
    flash[:notice] = t('users.2fa_enabled')
    redirect_to clean_redirect_param(:return_to) || user_edit_sign_in_path
  end

  def self.apply_sort(finder, sort:)
    case sort
    when 'name'
      finder.order(:name, :id) if sort == 'name'
    when 'scripts'
      finder.order('stats_script_count DESC, users.id')
    when 'total_installs'
      finder.order('stats_script_total_installs DESC, users.id')
    when 'created_script'
      finder.order('stats_script_last_created DESC, users.id')
    when 'updated_script'
      finder.order('stats_script_last_updated DESC, users.id')
    when 'daily_installs'
      finder.order('stats_script_daily_installs DESC, users.id')
    when 'fans'
      finder.order('stats_script_fan_score DESC, users.id')
    when 'ratings'
      finder.order('stats_script_ratings DESC, users.id')
    else
      finder.order(id: :desc)
    end
  end
end
