class CommentsController < ApplicationController
  include DiscussionHelper

  before_action :authenticate_user!, only: :create
  before_action :load_discussion

  def create
    comment = @discussion.comments.build(comments_params)
    comment.poster = current_user
    comment.save!
    redirect_to scoped_discussion_path(@discussion)
  end

  private

  def load_discussion
    @discussion = Discussion.find(params[:discussion_id])
  end

  def comments_params
    params.require(:comment).permit(:text, :text_markup)
  end
end