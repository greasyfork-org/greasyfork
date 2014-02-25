class HomeController < ApplicationController

	def index
	end

	def preview_markup
		render :text => view_context.format_user_text(params[:text], params[:markup])
	end

end
