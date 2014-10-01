require 'js_connect'

class HomeController < ApplicationController

	protect_from_forgery :except => [:sso]

	def index
		@highlighted_scripts = Script.listable.includes(:localized_attributes => :locale).order('daily_installs DESC').limit(100).sample(10)
	end

	def preview_markup
		if params[:url]
			begin
				text = ScriptImporter::BaseScriptImporter.download(params[:text])
			rescue ArgumentError => ex
				render :text => ex
				return
			end
		else
			text = params[:text]
		end
		render :text => view_context.format_user_text(text, params[:markup])
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

end
