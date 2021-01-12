class CommentsController < ApplicationController
  include DiscussionHelper
  include UserTextHelper

  before_action :authenticate_user!, except: :old_redirect
  before_action :load_discussion, except: :old_redirect
  before_action :check_ip, only: :create

  def create
    Comment.transaction do
      rating = params.dig(:comment, :discussion, :rating)
      params[:comment].delete(:discussion)
      @discussion.update!(rating: rating) if rating && @discussion.poster == current_user && @discussion.script
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
    notification_job = notification_job.set(wait: Comment::EDITABLE_PERIOD) unless Rails.env.development?
    notification_job.perform_later(@comment)

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
    Comment.transaction do
      if comment.first_comment? && @discussion.poster == current_user
        rating = params.dig(:comment, :discussion, :rating)
        title = params.dig(:comment, :discussion, :title)
        @discussion.update!(rating: rating) if rating && @discussion.for_script?
        @discussion.update!(title: title) if title && !@discussion.for_script?
        params[:comment].delete(:discussion)
      end
      comment.edited_at = Time.current
      comment.attachments.select { |attachment| params["remove-attachment-#{attachment.id}"] == '1' }.each(&:destroy!)
      comment.assign_attributes(comments_params)
      comment.construct_mentions(detect_possible_mentions(comment.text, comment.text_markup))
      comment.save!
    end

    redirect_to comment.path(locale: request_locale.code)
  end

  def destroy
    comment = @discussion.comments.not_deleted.find(params[:id])
    unless current_user&.moderator? || comment.deletable_by?(current_user)
      render_access_denied
      return
    end
    comment.soft_destroy!(by_user: current_user)
    redirect_to @discussion.path(locale: request_locale.code)
  end

  def old_redirect
    redirect_to Discussion.find_by!(migrated_from: ForumComment.find(params[:id]).DiscussionID).url(locale: request_locale.code), status: :moved_permanently
  end

  private

  def load_discussion
    @discussion = Discussion.find(params[:discussion_id] || params[:category_discussion_id])
  end

  def comments_params
    params.require(:comment).permit(:text, :text_markup, attachments: [])
  end
end
