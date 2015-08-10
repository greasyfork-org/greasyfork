require 'js_connect'

class HomeController < ApplicationController

	protect_from_forgery :except => [:sso]

	def index
		highlighted_scripts_ids = cache_with_log("scripts/highlighted/#{script_subset}/#{I18n.locale.to_s}") do
			highlighted_script_ids_for_locale(I18n.locale)
		end
		@highlighted_scripts = Script.includes(:localized_attributes => :locale).find(highlighted_scripts_ids.to_a)
	end

	def preview_markup
		if params[:url] == 'true'
			begin
				text = ScriptImporter::BaseScriptImporter.download(params[:text])
				absolute_text = ScriptImporter::BaseScriptImporter.absolutize_references(text, params[:text])
				text = absolute_text if !absolute_text.nil?
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

private

	TOP_SCRIPTS_PERCENTAGE = 0.1
	TOP_SCRIPTS_COUNT = 15

	# Sample from the top scripts.
	def highlighted_script_ids_for_locale(locale_code)
		# Use scripts in the passed locale first.
		locale_scripts = Script.listable(script_subset).joins(:localized_attributes => :locale).references([:localized_attributes, :locale]).where('localized_script_attributes.attribute_key' => 'name').where('locales.code' => I18n.locale).select(:id)
		locale_script_count = locale_scripts.count
		locale_scripts_listed = [(locale_script_count * TOP_SCRIPTS_PERCENTAGE).to_i, TOP_SCRIPTS_COUNT].min
		highlighted_scripts = Set.new + locale_scripts.order('daily_installs DESC').limit((locale_script_count * TOP_SCRIPTS_PERCENTAGE).to_i).sample(locale_scripts_listed).map{|s| s.id}

		# If we don't have enough, use scripts that aren't in the passed locale.
		if highlighted_scripts.length < TOP_SCRIPTS_COUNT
			total_script_count = Script.listable(script_subset).count
			Script.listable(script_subset).order('daily_installs DESC').limit((total_script_count * TOP_SCRIPTS_PERCENTAGE).to_i).select(:id).map{|s| s.id}.shuffle.each do |id|
				highlighted_scripts << id
				break if highlighted_scripts.length >= TOP_SCRIPTS_COUNT
			end
		end

		return highlighted_scripts.to_a.shuffle
	end

end
