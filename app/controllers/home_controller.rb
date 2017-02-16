require 'js_connect'

class HomeController < ApplicationController

	protect_from_forgery :except => [:sso]

	def index
		@ad_method = choose_ad_method
	end

	def preview_markup
		if params[:url] == 'true'
			begin
				text = ScriptImporter::BaseScriptImporter.download(params[:text])
				absolute_text = ScriptImporter::BaseScriptImporter.absolutize_references(text, params[:text])
				text = absolute_text if !absolute_text.nil?
			rescue ArgumentError => ex
				@text = ex
				render 'home/error'
				return
			end
		else
			text = params[:text]
		end
		render html: view_context.format_user_text(text, params[:markup])
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

		render :js => json
	end

	# used so that we can log in with a form rather than a link
	def external_login
		session[:remember_me] = params[:remember_me]
		redirect_to "/auth/#{params[:provider]}/"
	end

	def search
	end

end
