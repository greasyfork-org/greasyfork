require 'script_importer/script_syncer'
require 'uri'
require 'securerandom'

class UsersController < ApplicationController
  MAX_LIST_ENTRIES = 1000

  include Webhooks
  include BrowserCaching

  skip_before_action :verify_authenticity_token, only: [:webhook]

  before_action :authenticate_user!, except: [:show, :webhook, :index]
  before_action :authorize_for_moderators_only, only: [:ban, :do_ban]
  before_action :check_read_only_mode, except: [:index, :show]
  before_action :disable_browser_caching!, only: [:edit_sign_in]

  def index
    # Limit to 1000 results. Otherwise bots get at it and load way far into the list, which has performance problems.
    pp = per_page
    if params[:page].to_i > MAX_LIST_ENTRIES / pp
      render_404 'User list is limited to 1000 results.'
      return
    end

    # Pagination with search is also slow.
    if params[:q].present?
      if params[:page].to_i > 1
        redirect_to current_path_with_params(page: nil, per_page: nil)
        return
      end
      @paginate = false
    end

    @users = User

    @users = @users.where(['name like ?', "%#{User.sanitize_sql_like(params[:q])}%"]) if params[:q].present?

    @users = @users.where(email_domain: params[:email_domain]) if current_user&.moderator? && params[:email_domain]

    case params[:banned]
    when '1'
      @users = @users.banned
    when '0'
      @users = @users.not_banned
    end

    case params[:author]
    when '1'
      @users = @users.where(id: Script.not_deleted.joins(:authors).select(:user_id))
    when '0'
      @users = @users.where.not(id: Script.not_deleted.joins(:authors).select(:user_id))
    end

    if current_user&.moderator? && params[:same_ip]
      other_user = User.find(params[:same_ip])
      @users = @users.where(current_sign_in_ip: other_user.current_sign_in_ip) if other_user&.current_sign_in_ip
    end

    @users = self.class.apply_sort(@users, sort: params[:sort]).paginate(page: params[:page], per_page: pp, total_entries: [@users.count, MAX_LIST_ENTRIES].min).load
    @user_script_counts = Script.listable(script_subset).joins(:authors).where(authors: { user_id: @users.map(&:id) }).group(:user_id).count

    @bots = 'noindex,follow' if !params[:sort].nil? || !params[:q].nil?
    @title = t('users.listing_title')
    @canonical_params = [:page, :per_page, :sort, :q]

    render layout: 'base'
  end

  def show
    # TODO: sort scripts by name, keeping into account localization
    user = User.order('scripts.default_name')
    # current user will display discussions
    user = if !current_user.nil? && (current_user.id == params[:id].to_i)
             user.includes(scripts: [:discussions, :script_type, :script_delete_type, { localized_attributes: :locale }])
           else
             user.includes(scripts: [:script_type, :script_delete_type, { localized_attributes: :locale }])
           end
    @user = user.find(params[:id])

    return if redirect_to_slug(@user, :id)

    @same_user = !current_user.nil? && current_user.id == @user.id

    respond_to do |format|
      format.html do
        @by_sites = TopSitesService.get_top_by_sites(script_subset: script_subset, user_id: @user.id)

        @scripts = (@same_user || (!current_user.nil? && current_user.moderator?)) ? @user.scripts : @user.scripts.listable_including_libraries(script_subset)
        @user_has_scripts = !@scripts.empty?
        @scripts = ScriptsController.apply_filters(@scripts, params.reverse_merge(language: 'all'), script_subset).paginate(per_page: 100, page: params[:page] || 1)
        @other_site_scripts = script_subset == :sleazyfork ? @user.scripts.listable(:greasyfork).count : 0

        @bots = 'noindex,follow' if [:per_page, :set, :site, :sort, :language].any? { |name| params[name].present? }

        @link_alternates = [
          { url: current_path_with_params(format: :json), type: 'application/json' },
          { url: current_path_with_params(format: :jsonp, callback: 'callback'), type: 'application/javascript' },
        ]
        @canonical_params = [:id, :page, :per_page, :set, :site, :sort, :language]
        @ad_method = 'cf' if ads_enabled?

        if @same_user
          conversation_scope = current_user.conversations.includes(:users, :stat_last_poster)
          @recent_conversations = conversation_scope.order(stat_last_message_date: :desc).where(stat_last_message_date: 1.month.ago..)
          @more_conversations = conversation_scope.count > @recent_conversations.count
        end

        @show_profile = !@user.banned? && UserRestrictionService.new(@user).allow_posting_profile?

        render layout: 'base'
      end
      format.json { render json: @user.as_json(include: @same_user ? :scripts : :all_listable_scripts) }
      format.jsonp { render json: @user.as_json(include: @same_user ? :scripts : :all_listable_scripts), callback: clean_json_callback_param }
    end
  end

  def webhook_info
    @user = current_user
    if request.post?
      @user.generate_webhook_secret
      @user.save!
    end
    @webhook_scripts = Script.not_deleted.joins(:authors).where(authors: { user_id: @user.id }).where('sync_identifier LIKE "https://github.com/%" OR sync_identifier LIKE "https://raw.githubusercontent.com/%" OR sync_identifier LIKE "https://bitbucket.org/%" OR sync_identifier LIKE "https://gitlab.com/%"').includes(:script_sync_type)
  end

  def webhook
    user = User.find(params[:user_id])
    changes, git_url = if request.headers['User-Agent'] == 'Bitbucket-Webhooks/2.0'
                         process_bitbucket_webhook(user)
                       elsif request.headers['X-Gitlab-Token'].present?
                         process_gitlab_webhook(user)
                       else
                         process_github_webhook(user)
                       end
    process_webhook_changes(changes, git_url) if changes
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
    sign_in current_user, bypass: true
    flash[:notice] = t('users.password_removed')
    redirect_to user_edit_sign_in_path
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
    user.lock_all_scripts!(reason: params[:reason], moderator: current_user, delete_type: params[:script_delete_type_id]) if params[:script_delete_type_id].present?
    user.delete_all_comments!(by_user: user) if params[:delete_comments] == '1'
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

  def notifications
    @user = current_user
  end

  def update_notifications
    current_user.update!(params.require(:user).permit(:author_email_notification_type_id, :subscribe_on_discussion, :subscribe_on_comment, :subscribe_on_conversation_starter, :subscribe_on_conversation_receiver, :notify_on_mention))
    current_user.discussion_subscriptions.destroy_all if params[:unsubscribe_all_discussions] == '1'
    flash[:notice] = t('users.notifications.save_success')
    redirect_to user_path(current_user)
  end

  def unsubscribe_all
    current_user.update!(
      author_email_notification_type_id: User::AUTHOR_NOTIFICATION_NONE,
      subscribe_on_discussion: false,
      subscribe_on_comment: false,
      subscribe_on_conversation_starter: false,
      subscribe_on_conversation_receiver: false,
      notify_on_mention: false
    )
    current_user.discussion_subscriptions.destroy_all
    flash[:notice] = t('users.notifications.unsubscribe_all_success')
    redirect_to user_path(current_user)
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
