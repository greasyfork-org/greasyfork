class DiscussionsController < ApplicationController
  include DiscussionHelper
  include ScriptAndVersions
  include UserTextHelper
  include PageCache
  include DiscussionRestrictions

  FILTER_RESULT = Struct.new(:category, :by_user, :related_to_me, :read_status, :locale, :result, :visibility)

  before_action :check_read_only_mode, except: [:show, :index, :old_redirect]
  before_action :authenticate_user!, only: [:new, :create, :subscribe, :unsubscribe]
  before_action :greasy_only, only: :new
  before_action :check_ip, only: :create
  before_action :load_discussion, only: :show
  before_action :mark_notifications_read, only: :show
  before_action :cn_greasy_404!, only: :index
  before_action :check_user_restrictions, only: [:new, :create]
  skip_before_action :set_locale, only: [:old_redirect]

  layout 'discussions', only: :index
  layout 'application', only: [:new, :create]

  def index
    respond_to do |format|
      format.html do
        should_cache_page = current_user.nil? && request.format.html? && (params.keys - %w[locale controller action site page]).none?
        cache_page(should_cache_page ? "#{site_cache_key}/discussion/index/#{params.values.join('/')}" : nil, ttl: 5.minutes) do
          if params[:q].presence
            with = { discussion_category_id: discussion_category_filter.pluck(:id) }

            if current_user
              case params[:me]
              when 'started'
                with[:discussion_starter_id] = current_user.id
              when 'comment'
                with[:poster_id] = current_user.id
              when 'script'
                with[:script_id] = current_user.script_ids
              when 'subscribed'
                with[:discussion_id] = current_user.discussion_subscriptions.pluck(:discussion_id)
              else
                params[:me] = nil
              end
            end

            if params[:show_locale]
              locale = Locale.fetch_locale(params[:show_locale])
              with[:locale_id] = locale.id if locale
            end

            case script_subset
            when :sleazyfork
              with[:sensitive] = true
            when :greasyfork
              with[:sensitive] = false
            when :all
              # No restrictions
            else
              raise "Unknown subset #{script_subset}"
            end

            param_to_search_option = {
              'comment_created' => { created: :desc },
              'discussion_created' => { discussion_created: :desc },
              'last_comment' => { discussion_last_reply: :desc },
            }
            order = param_to_search_option[params[:sort]]

            @comments = Comment.search(
              params[:q].presence || '*',
              fields: ['discussion_title^2', 'text'],
              where: with,
              order:,
              page: page_number,
              per_page: per_page(default: 25)
            )
            @comments_to_discussions = @comments.map { |c| [c, c.discussion] }
            @discussions = @comments_to_discussions.map(&:last)
            @filter_result = FILTER_RESULT.new(category: params[:category], related_to_me: params[:me], locale:)
            @bots = 'noindex'

          else

            order = case params[:sort]
                    when 'discussion_created' then { id: :desc }
                    else { stat_last_reply_date: :desc }
                    end

            @discussions = Discussion
                           .includes(:poster, :script, :discussion_category, :stat_first_comment, :stat_last_replier)
                           .order(order)

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

            @filter_result = apply_filters(@discussions)
            if @filter_result.is_a?(String)
              render_404(@filter_result)
              return
            end

            @discussions = @filter_result.result
            @discussions = apply_pagination(@discussions, default_per_page: 25)
            @bots = 'noindex' unless page_number == 1
          end

          @discussion_ids_read = DiscussionRead.read_ids_for(@discussions, current_user) if current_user
          @possible_locales = Locale.with_discussions.order(:code)

          render_to_string
        end
      end
    end
  end

  def show
    if cn_greasy? && !params[:script_id]
      render_404('404')
      return
    end

    @canonical_params = [:id, :script_id, :category, :page, :per_page]

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
        @ad_method = choose_ad_method_for_discussion(@discussion)
        @placed_ad = true

        render layout: @script ? 'scripts' : 'application'
      end
      format.all do
        head :unprocessable_content
      end
    end
  end

  def new
    @discussion = Discussion.new(poster: current_user)
    if current_user&.moderator? && params[:report_id]
      report = Report.find(params[:report_id])
      @discussion.report = report
      users_to_mention = case report.item
                         when User
                           [report.item]
                         when Comment, Discussion
                           [report.item.poster]
                         else
                           report.item&.users || []
                         end
      text = users_to_mention.map { |user| user.name.match?(/\s+/) ? "@\"#{user.name}\"" : "@#{user.name}" }.join(' ')
    elsif params[:category] && params[:category] != DiscussionCategory::SCRIPT_DISCUSSIONS_KEY
      @discussion.discussion_category = DiscussionCategory.find_by(category_key: params[:category])
    end
    @discussion.comments.build(poster: current_user, text_markup: current_user&.preferred_markup, text:)
    @subscribe = current_user.subscribe_on_discussion
  end

  def create
    @discussion = discussion_scope.new(discussion_params)
    @discussion.poster = @discussion.comments.first.poster = current_user
    if @script
      @discussion.script = @script
      @discussion.discussion_category = DiscussionCategory.script_discussions
      @discussion.rating = Discussion::RATING_QUESTION if @discussion.by_script_author?
    end

    if @discussion.report && @discussion.report.item.is_a?(Script)
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

    DiscussionSubscription.find_or_create_by!(user: current_user, discussion: @discussion) if @subscribe

    if @discussion.script
      users_to_subscribe = @discussion.script.users.where(subscribe_on_script_discussion: true) - [current_user]
      users_to_subscribe.each do |user|
        DiscussionSubscription.find_or_create_by!(user:, discussion: @discussion)
      end
    end

    notification_job = CommentNotificationJob
    notification_job = notification_job.set(wait: Comment::EDITABLE_PERIOD) unless Rails.env.local?
    notification_job.perform_later(@discussion.comments.first)

    CommentSpamCheckJob.perform_later(@discussion.comments.first, request.ip, request.user_agent, request.referer) unless current_user.discussions.count > 3

    redirect_to @discussion.path(locale: request_locale.code)
  end

  def destroy
    discussion = discussion_scope.find(params[:id])
    normally_deletable = discussion.deletable_by?(current_user)
    unless normally_deletable || current_user&.moderator?
      render_access_denied
      return
    end

    discussion.soft_destroy!(by_user: current_user)
    ModeratorAction.create!(moderator: current_user, discussion:, action_taken: :delete) unless normally_deletable

    if discussion.script
      redirect_to script_path(discussion.script)
    else
      redirect_to discussions_path(locale: request_locale.code)
    end
  end

  def subscribe
    discussion = discussion_scope.find(params[:id])
    DiscussionSubscription.find_or_create_by!(user: current_user, discussion:)
    respond_to do |format|
      format.js { head :ok }
      format.all { redirect_to discussion.path(locale: request_locale.code) }
    end
  end

  def unsubscribe
    discussion = discussion_scope.find(params[:id])
    DiscussionSubscription.find_by(user: current_user, discussion:)&.destroy
    respond_to do |format|
      format.js { head :ok }
      format.all { redirect_to discussion.path(locale: request_locale.code) }
    end
  end

  def old_redirect
    redirect_to Discussion.find_by!(migrated_from: params[:id]).path(locale: detect_locale_code), status: :moved_permanently
  end

  def mark_all_read
    filter_result = apply_filters(Discussion.all)
    if filter_result.is_a?(String)
      render_404(filter_result)
      return
    end

    if filter_result.category || filter_result.related_to_me || filter_result.by_user
      now = Time.current
      ids = filter_result.result.pluck(:id)
      DiscussionRead.upsert_all(ids.map { |discussion_id| { discussion_id:, user_id: current_user.id, read_at: now } }) if ids.any?
    else
      current_user.update!(discussions_read_since: Time.current)
    end

    redirect_back_or_to(discussions_path)
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
    attrs = [:rating, :title, :discussion_category_id, { comments_attributes: [[:text, :text_markup, { attachments: [] }]] }]
    attrs += [:report_id] if current_user&.moderator?
    params.expect(discussion: attrs)
  end

  def record_view(discussion)
    DiscussionRead.upsert({ user_id: current_user.id, discussion_id: discussion.id, read_at: Time.current })
  end

  def discussion_category_filter
    category_scope = DiscussionCategory.visible_to_user(current_user)
    case params[:category]
    when DiscussionCategory::NO_SCRIPTS_KEY
      category_scope.non_script
    when nil
      category_scope
    else
      category_scope.where(category_key: params[:category])
    end
  end

  # Returns a FILTER_RESULT Struct representing the query, or a String if there was an error.
  def apply_filters(discussions)
    discussions = discussions.where(discussion_category_id: discussion_category_filter.pluck(:id))
    category = params[:category]

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
      return 'User does not exist.' unless by_user

      discussions = discussions.with_comment_by(by_user)
    end

    if params[:show_locale].present?
      locale = Locale.fetch_locale(params[:show_locale])
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

    if current_user&.moderator?
      visibility = params[:visibility]
      case visibility
      when 'all'
        # No change
      when 'private'
        discussions = discussions.where('discussions.review_reason IS NOT NULL OR discussions.deleted_at IS NOT NULL')
      else
        visibility = nil
        discussions = discussions.visible
      end
    else
      discussions = discussions.permissive_visible(current_user)
    end

    FILTER_RESULT.new(category, by_user, related_to_me, read_status, locale, discussions, visibility)
  end

  def load_discussion
    # Allow mods and the poster to see discussions under review.
    @discussion = discussion_scope(permissive: true).find(params[:id])
  end

  def mark_notifications_read
    return unless current_user

    Notification.unread.where(user: current_user, item: [@discussion.comments]).mark_read!
    Notification.unread.where(user: current_user, item: [@discussion.script], notification_type: Notification::NOTIFICATION_TYPE_CONSECUTIVE_BAD_RATINGS).mark_read! if @discussion.script
    load_notification_count
  end
end
