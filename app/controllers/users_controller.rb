class UsersController < ApplicationController

	def show
		@user = User.order('scripts.name')
		# current user will display discussions
		if !current_user.nil? and current_user.id == params[:id].to_i
			@user = @user.includes(:scripts => :discussions)
		else
			@user = @user.includes(:scripts)
		end
		@user = @user.find(params[:id])
		return if redirect_to_slug(@user, :id)
	end

end
