class UsersController < ApplicationController

	def show
		@user = User.includes(:scripts).order('scripts.name').find(params[:id])
	end

end
