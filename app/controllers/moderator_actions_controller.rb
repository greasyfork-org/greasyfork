class ModeratorActionsController < ApplicationController
  def index
    @actions = ModeratorAction.includes(:script, :moderator, :user, :report).order(id: :desc).paginate(page: params[:page], per_page: 100)
    @bots = 'noindex'
    @canonical_params = [:page]
    render layout: 'base'
  end
end
