class ModeratorActionsController < ApplicationController
  def index
    respond_to do |format|
      format.html do
        @actions = apply_pagination(ModeratorAction.includes(:script, :moderator, :user, :report).order(id: :desc), default_per_page: 100)
        @bots = 'noindex'
        @canonical_params = [:page]
        render layout: 'base'
      end
    end
  end
end
