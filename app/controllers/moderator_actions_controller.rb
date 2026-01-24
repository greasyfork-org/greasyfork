class ModeratorActionsController < ApplicationController
  def index
    respond_to do |format|
      format.html do
        @actions = ModeratorAction.includes(:script, :moderator, :user, :report).order(id: :desc).paginate(page: page_number, per_page: per_page(default: 100))
        @bots = 'noindex'
        @canonical_params = [:page]
        render layout: 'base'
      end
    end
  end
end
