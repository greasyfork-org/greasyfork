class DiscussionsController < ApplicationController
  include DiscussionHelper
  include ScriptAndVersions
  include UserTextHelper

  FILTER_RESULT = Struct.new(:category, :by_user, :related_to_me, :read_status, :locale, :result)

  before_action :authenticate_user!, only: [:new, :create, :subscribe, :unsubscribe]
  before_action :greasy_only, only: :new
  before_action :check_ip, only: :create

  layout 'discussions', only: :index
  layout 'application', only: [:new, :create]

  def index
    @discussions = Discussion
                   .visible
                   .includes(:poster, :script, :discussion_category, :stat_first_comment, :stat_last_replier)
                   .order(stat_last_reply_date: :desc)
    case script_subset
    when :sleazyfork
      @discussions = @discussions.where(scripts: { sensitive: true })
    when :greasyfork
      @discussions = @discussions.where(scripts: { sensitive: [nil, false] })
    when :all
      # No restrictions
    else
      raise "Unknown subset #{script_subset}"
    end

    @discussions = @discussions.where(scripts: { script_delete_type_id: nil }) unless current_user&.moderator?

    @filter_result = apply_filters(@discussions)

    @discussions = @filter_result.result
    @discussions = @discussions.paginate(page: params[:page], per_page: 25)
    @bots = 'noindex' unless params[:page].nil?

    @discussion_ids_read = DiscussionRead.read_ids_for(@discussions, current_user) if current_user

    @possible_locales = Locale.with_discussions.order(:code)
  end

  def show
    # Allow mods and the poster to see discussions under review.
    @discussion = discussion_scope(permissive: true).find(params[:id])

    if @discussion.script
      return if handle_publicly_deleted(@discussion.script)

      case script_subset
      when :sleazyfork
        unless @discussion.script.sensitive?
          render_404
          return
        end
      when :greasyfork
        if @discussion.script.sensitive?
          render_404
          return
        end
      when :all
        # No restrictions
      else
        raise "Unknown subset #{script_subset}"
      end
    end

    respond_to do |format|
      format.html do
        @comment = @discussion.comments.build(text_markup: current_user&.preferred_markup)
        @subscribe = current_user&.subscribe_on_comment || current_user&.subscribed_to?(@discussion)

        record_view(@discussion) if current_user

        render layout: @script ? 'scripts' : 'application'
      end
      format.all do
        head :unprocessable_entity
      end
    end
  end

  def new
    @discussion = Discussion.new(poster: current_user)
    if current_user&.moderator? && params[:report_id]
      report = Report.find(params[:report_id])
      @discussion.report = report
      users_to_mention = report.item.users.map { |user| user.name.match?(/\s+/) ? "@\"#{user.name}\"" : "@#{user.name}" }
      text = users_to_mention.join(' ')
    elsif params[:category] && params[:category] != DiscussionCategory::SCRIPT_DISCUSSIONS_KEY
      @discussion.discussion_category = DiscussionCategory.find_by(category_key: params[:category])
    end
    @discussion.comments.build(poster: current_user, text_markup: current_user&.preferred_markup, text: text)
    @subscribe = current_user.subscribe_on_discussion
  end

  def create
    if current_user.email&.ends_with?('163.com') && current_user.created_at > 7.days.ago && current_user.discussions.where(created_at: 1.hour.ago..).any?
      render plain: 'Please try again later.'
      return
    end

    @discussion = discussion_scope.new(discussion_params)
    @discussion.poster = @discussion.comments.first.poster = current_user
    if @script
      @discussion.script = @script
      @discussion.discussion_category = DiscussionCategory.script_discussions
    end

    if @discussion.report
      @discussion.script = @discussion.report.item
      @discussion.rating = Discussion::RATING_QUESTION
      @discussion.discussion_category = DiscussionCategory.script_discussions
    end

    comment = @discussion.comments.first
    comment.first_comment = true
    @subscribe = params[:subscribe] == '1'

    recaptcha_ok = current_user.needs_to_recaptcha? ? verify_recaptcha : true
    unless recaptcha_ok && @discussion.valid?
      if @discussion.script && !@discussion.report
        render :new, layout: 'scripts'
      else
        render :new
      end
      return
    end

    comment.construct_mentions(detect_possible_mentions(comment.text, comment.text_markup))
    @discussion.save!

    notification_job = CommentNotificationJob
    notification_job = notification_job.set(wait: Comment::EDITABLE_PERIOD) unless Rails.env.development?
    notification_job.perform_later(@discussion.comments.first)

    DiscussionSubscription.find_or_create_by!(user: current_user, discussion: @discussion) if @subscribe

    AkismetDiscussionCheckingJob.perform_later(@discussion, request.ip, request.user_agent, request.referer)

    redirect_to @discussion.path(locale: request_locale.code)
  end

  def destroy
    discussion = discussion_scope.find(params[:id])
    discussion.soft_destroy!
    if discussion.script
      redirect_to script_path(discussion.script)
    else
      redirect_to discussions_path(locale: request_locale.code)
    end
  end

  def subscribe
    discussion = discussion_scope.find(params[:id])
    DiscussionSubscription.find_or_create_by!(user: current_user, discussion: discussion)
    respond_to do |format|
      format.js { head :ok }
      format.all { redirect_to discussion.path(locale: request_locale.code) }
    end
  end

  def unsubscribe
    discussion = discussion_scope.find(params[:id])
    DiscussionSubscription.find_by(user: current_user, discussion: discussion)&.destroy
    respond_to do |format|
      format.js { head :ok }
      format.all { redirect_to discussion.path(locale: request_locale.code) }
    end
  end

  def old_redirect
    redirect_to Discussion.find_by!(migrated_from: params[:id]).url(locale: request_locale.code), status: :moved_permanently
  end

  def mark_all_read
    filter_result = apply_filters(Discussion.all)

    if filter_result.category || filter_result.related_to_me || filter_result.by_user
      now = Time.current
      ids = filter_result.result.pluck(:id)
      DiscussionRead.upsert_all(ids.map { |discussion_id| { discussion_id: discussion_id, user_id: current_user.id, read_at: now } }) if ids.any?
    else
      current_user.update!(discussions_read_since: Time.current)
    end

    redirect_back(fallback_location: discussions_path)
  end

  private

  def discussion_scope(permissive: false)
    scope = if params[:script_id]
              @script = Script.find(params[:script_id])
              @script.discussions
            else
              Discussion
            end
    scope = scope.where(discussion_category: DiscussionCategory.visible_to_user(current_user))
    if permissive && current_user
      scope.permissive_visible(current_user)
    else
      scope.visible
    end
  end

  def discussion_params
    attrs = [:rating, :title, :discussion_category_id, :report_id, { comments_attributes: [:text, :text_markup, { attachments: [] }] }]
    attrs += [:report_id] if current_user&.moderator?
    params
      .require(:discussion)
      .permit(attrs)
  end

  def record_view(discussion)
    DiscussionRead.upsert({ user_id: current_user.id, discussion_id: discussion.id, read_at: Time.current })
  end

  def apply_filters(discussions)
    category_scope = DiscussionCategory.visible_to_user(current_user)
    case params[:category]
    when DiscussionCategory::NO_SCRIPTS_KEY
      category = params[:category]
      discussions = discussions.where(discussion_category_id: category_scope.non_script.pluck(:id))
    when nil
      discussions = discussions.where(discussion_category_id: category_scope.pluck(:id))
    else
      category = params[:category]
      discussions = discussions.where(discussion_category_id: category_scope.find_by!(category_key: category).id)
    end

    if current_user
      related_to_me = params[:me]
      case related_to_me
      when 'started'
        discussions = discussions.where(poster: current_user)
      when 'comment'
        discussions = discussions.with_comment_by(current_user)
      when 'script'
        discussions = discussions.where(script_id: current_user.script_ids)
      when 'subscribed'
        discussions = discussions.where(id: current_user.discussion_subscriptions.pluck(:discussion_id))
      else
        related_to_me = nil
      end
    end

    if params[:user].to_i > 0
      by_user = User.find_by(id: params[:user].to_i)
      discussions = discussions.with_comment_by(by_user) if by_user
    end

    if params[:show_locale].present?
      locale = Locale.find_by(code: params[:show_locale])
      discussions = discussions.where(locale_id: locale) if locale
    end

    # This needs to be the last.
    if current_user
      read_status = params[:read]
      case read_status
      when 'read'
        discussions = discussions.where(id: DiscussionRead.read_ids_for(discussions, current_user))
      when 'unread'
        discussions = discussions.where.not(id: DiscussionRead.read_ids_for(discussions, current_user))
      else
        read_status = nil
      end
    end

    FILTER_RESULT.new(category, by_user, related_to_me, read_status, locale, discussions)
  end
end
