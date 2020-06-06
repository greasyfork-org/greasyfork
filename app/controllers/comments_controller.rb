class CommentsController < ApplicationController
  include DiscussionHelper

  before_action :authenticate_user!
  before_action :load_discussion
  before_action :moderators_only, only: :destroy

  def create
    @comment = @discussion.comments.build(comments_params)
    @comment.poster = current_user
    if @comment.save
      @comment.notify_script_authors!
      redirect_to @comment.path
      return
    end
    if @discussion.script
      @script = @discussion.script
      render 'discussions/show', layout: 'scripts'
    else
      render 'discussions/show'
    end
  end

  def update
    comment = @discussion.comments.find(params[:id])
    unless comment.poster && comment.poster == current_user
      render_access_denied
      return
    end
    Comment.transaction do
      if comment.first_comment?
        rating = params[:comment][:discussion].delete(:rating)
        comment.discussion.update!(rating: rating)
      end
      comment.edited_at = Time.now
      comment.attachments.select { |attachment| params["remove-attachment-#{attachment.id}"] == '1' }.each(&:destroy!)
      comment.update!(comments_params)
    end
    redirect_to comment.path(locale: request_locale.code)
  end

  def destroy
    comment = @discussion.comments.find(params[:id])
    comment.destroy!
    redirect_to @discussion.path
  end

  private

  def load_discussion
    @discussion = Discussion.find(params[:discussion_id])
  end

  def comments_params
    params.require(:comment).permit(:text, :text_markup, attachments: [])
  end
end
