class ModeratorActionsController < ApplicationController

	def index
		@actions = ModeratorAction.includes([:script, :moderator, :user]).order('id desc').all
	end
end
