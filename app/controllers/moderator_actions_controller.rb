class ModeratorActionsController < ApplicationController

	def index
		@actions = ModeratorAction.includes([:script, :moderator]).all
	end
end
