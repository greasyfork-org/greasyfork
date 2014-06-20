class ModeratorActionsController < ApplicationController

	def index
		@actions = ModeratorAction.includes([:script, :moderator, :user]).order('id desc').paginate(:page => params[:page], :per_page => 100)
	end
end
