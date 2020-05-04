class DiscussionsController < ApplicationController
  include DiscussionHelper

  before_action :authenticate_user!, only: :create

  def show
    @discussion = discussion_scope.find(params[:id])
    @comment = Comment.new
    render layout: 'scripts' if @script
  end

  def create
    discussion = discussion_scope.build(discussion_params)
    discussion.poster = discussion.comments.first.poster = current_user
    discussion.script = @script
    discussion.save!
    redirect_to discussion.path
  end

  private

  def discussion_scope
    if params[:script_id]
      @script = Script.find(params[:script_id])
      @script.new_discussions
    else
      Discussion
    end
  end

  def discussion_params
    params.require(:discussion).permit(:rating, comments_attributes: [:text, :text_markup])
  end
end
