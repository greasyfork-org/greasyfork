class CommentsController < ApplicationController
  include DiscussionHelper

  before_action :authenticate_user!, except: :old_redirect
  before_action :load_discussion, except: :old_redirect
  before_action :moderators_only, only: :destroy
  before_action :check_ip, only: :create

  def create
    Comment.transaction do
      rating = params.dig(:comment, :discussion, :rating)
      params[:comment].delete(:discussion)
      @discussion.update!(rating: rating) if rating && @discussion.poster == current_user && @discussion.script
      @comment = @discussion.comments.build(comments_params)
      @comment.poster = current_user
      @comment.save!

      if params[:subscribe] == '1'
        DiscussionSubscription.find_or_create_by!(user: current_user, discussion: @discussion)
      else
        DiscussionSubscription.find_by(user: current_user, discussion: @discussion)&.destroy
      end
    end

    @comment.send_notifications!

    redirect_to @comment.path
  rescue ActiveRecord::Rollback
    if @discussion.script
      @script = @discussion.script
      render 'discussions/show', layout: 'scripts'
    else
      render 'discussions/show'
    end
  end

  def update
    comment = @discussion.comments.not_deleted.find(params[:id])
    unless comment.poster && comment.poster == current_user
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
      comment.edited_at = Time.now
      comment.attachments.select { |attachment| params["remove-attachment-#{attachment.id}"] == '1' }.each(&:destroy!)
      comment.update!(comments_params)
    end
    redirect_to comment.path(locale: request_locale.code)
  end

  def destroy
    comment = @discussion.comments.not_deleted.find(params[:id])
    comment.soft_destroy!(by_user: current_user)
    redirect_to @discussion.path
  end

  def old_redirect
    redirect_to Discussion.find_by!(migrated_from: ForumComment.find(params[:id]).DiscussionID).url, status: 301
  end

  private

  def load_discussion
    @discussion = Discussion.find(params[:discussion_id] || params[:category_discussion_id])
  end

  def comments_params
    params.require(:comment).permit(:text, :text_markup, attachments: [])
  end
end
