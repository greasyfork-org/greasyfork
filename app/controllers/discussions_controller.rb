class DiscussionsController < ApplicationController
  include DiscussionHelper

  before_action :authenticate_user!, only: :create
  before_action :moderators_only, only: :destroy

  def index
    @discussions = Discussion
                       .includes(:poster, :script)
                       .order(stat_last_reply_date: :desc)
                       .paginate(page: params[:page], per_page: 25)
  end

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
    discussion.comments.first.notify_script_authors!
    redirect_to discussion.path
  end

  def destroy
    discussion = discussion_scope.find(params[:id])
    discussion.destroy!
    if discussion.script
      redirect_to script_path(discussion.script)
    else
      redirect_to root_path
    end
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
