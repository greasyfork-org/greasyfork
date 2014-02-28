require 'js_connect'

class HomeController < ApplicationController

	def index
	end

	def preview_markup
		render :text => view_context.format_user_text(params[:text], params[:markup])
	end

	def sso
		client_id = Greasyfork::Application.config.vanilla_jsconnect_clientid
		secret = Greasyfork::Application.config.vanilla_jsconnect_secret
		user = {}

		if user_signed_in?
			user["uniqueid"] = current_user.id.to_s
			user["name"] = current_user.name
			user["email"] = current_user.email
			user["photourl"] = ""
		end

		secure = true # this should be true unless you are testing.
		json = JsConnect.getJsConnectString(user, self.params, client_id, secret, secure)

		render :text => json
	end

end
