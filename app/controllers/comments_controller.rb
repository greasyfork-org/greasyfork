class CommentsController < ApplicationController
  include DiscussionHelper
  include UserTextHelper
  include DiscussionRestrictions

  before_action :check_read_only_mode, except: :old_redirect
  before_action :authenticate_user!, except: :old_redirect
  before_action :load_discussion, except: :old_redirect
  before_action :check_ip, only: :create
  before_action :check_user_restrictions, only: [:new, :create]

  skip_before_action :set_locale, only: [:old_redirect]

  def create
    Comment.transaction do
      rating = params.dig(:comment, :discussion, :rating)
      params[:comment].delete(:discussion)
      @discussion.update!(rating:) if rating && @discussion.poster == current_user && @discussion.script
      @comment = @discussion.comments.build(comments_params)
      @comment.poster = current_user
      @comment.construct_mentions(detect_possible_mentions(@comment.text, @comment.text_markup))
      @comment.save!
      case params[:subscribe]
      when '1'
        DiscussionSubscription.find_or_create_by!(user: current_user, discussion: @discussion)
      when '0'
        DiscussionSubscription.find_by(user: current_user, discussion: @discussion)&.destroy
      end
    end

    notification_job = CommentNotificationJob
    notification_job = notification_job.set(wait: Comment::EDITABLE_PERIOD) unless Rails.env.local?
    notification_job.perform_later(@comment)

    CommentSpamCheckJob.perform_later(@comment, request.ip, request.user_agent, request.referer) unless current_user.comments.count > 3

    redirect_to @comment.path(locale: request_locale.code)
  rescue ActiveRecord::RecordInvalid
    if @discussion.script
      @script = @discussion.script
      render 'discussions/show', layout: 'scripts'
    else
      render 'discussions/show'
    end
  end

  def update
    comment = @discussion.comments.not_deleted.find(params[:id])
    unless comment.editable_by?(current_user)
      render_access_denied
      return
    end

    begin
      Comment.transaction do
        if comment.first_comment? && @discussion.poster == current_user
          rating = params.dig(:comment, :discussion, :rating)
          title = params.dig(:comment, :discussion, :title)
          @discussion.update!(rating:) if rating && @discussion.for_script?
          @discussion.update!(title:) if title && !@discussion.for_script?
          params[:comment].delete(:discussion)
        end
        comment.edited_at = Time.current
        comment.assign_attributes(comments_params)
        comment.attachments.reject(&:new_record?).select { |attachment| params["remove-attachment-#{attachment.signed_id}"] == '1' }.each(&:destroy!)
        comment.construct_mentions(detect_possible_mentions(comment.text, comment.text_markup))
        comment.save!
      end
    rescue ActiveRecord::RecordInvalid
      flash[:alert] = comment.errors.full_messages.to_sentence
    end

    redirect_to comment.path(locale: request_locale.code)
  end

  def destroy
    comment = @discussion.comments.not_deleted.find(params[:id])
    normally_deletable = comment.deletable_by?(current_user)

    unless normally_deletable || current_user&.moderator?
      render_access_denied
      return
    end
    comment.soft_destroy!(by_user: current_user)
    ModeratorAction.create!(moderator: current_user, comment:, action_taken: :delete) unless normally_deletable

    redirect_to @discussion.path(locale: request_locale.code)
  end

  def old_redirect
    redirect_to Discussion.find_by!(migrated_from: ForumComment.find(params[:id]).DiscussionID).path(locale: detect_locale_code), status: :moved_permanently
  end

  private

  def load_discussion
    @discussion = Discussion.find(params[:discussion_id] || params[:category_discussion_id])
  end

  def comments_params
    params.expect(comment: [:text, :text_markup, { attachments: [] }])
  end
end
