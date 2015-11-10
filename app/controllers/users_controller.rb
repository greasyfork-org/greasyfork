require 'script_importer/script_syncer'
require 'uri'

class UsersController < ApplicationController

	skip_before_action :verify_authenticity_token, :only => [:webhook]

	before_filter :authenticate_user!, :except => [:show, :webhook, :index]
	before_filter :authorize_for_moderators_only, :only => [:ban, :do_ban]

	HMAC_DIGEST = OpenSSL::Digest.new('sha1')

	def index
		@users = User.includes("#{script_subset}_listable_scripts".to_sym).references(:scripts).group('users.id').order(self.class.get_sort(params)).paginate(page: params[:page], per_page: get_per_page)
	end

	def show
		# TODO sort scripts by name, keeping into account localization
		user = User.order('scripts.default_name')
		# current user will display discussions
		if !current_user.nil? and current_user.id == params[:id].to_i
			user = user.includes(:scripts => [:discussions, :script_type, :script_delete_type, :localized_attributes => :locale])
		else
			user = user.includes(:scripts => [:script_type, :script_delete_type, :localized_attributes => :locale])
		end
		@user = user.find(params[:id])

		return if redirect_to_slug(@user, :id)

		@same_user = !current_user.nil? && current_user.id == @user.id

		respond_to do |format|
			format.html {
				@by_sites = ScriptsController.get_top_by_sites(script_subset)

				@scripts = (@same_user || (!current_user.nil? && current_user.moderator?)) ? @user.scripts : @user.scripts.listable(script_subset)
				@user_has_scripts = !@scripts.empty?
				@scripts = ScriptsController.apply_filters(@scripts, params, script_subset)
				@other_site_scripts = script_subset == :sleazyfork ? @user.scripts.listable(:greasyfork).count : 0

				@bots = 'noindex,follow' if !params[:sort].nil?

				@link_alternates = [
					{:url => url_for(params.merge({:only_path => true, :format => :json})), :type => 'application/json'},
					{:url => url_for(params.merge({:only_path => true, :format => :jsonp, :callback => 'callback'})), :type => 'application/javascript'}
				]
				@canonical_params = [:id, :page, :per_page, :set, :site, :sort]
			}
			format.json { render :json => @user.as_json(include: @same_user ? :scripts : :all_listable_scripts) }
			format.jsonp { render :json => @user.as_json(include: @same_user ? :scripts : :all_listable_scripts), :callback => clean_json_callback_param }
		end
	end

	def webhook_info
		@user = current_user
		if request.post?
			@user.generate_webhook_secret
			@user.save!
		end
		@github_scripts = Script.not_deleted.where(:user_id => @user.id).where('sync_identifier LIKE "https://github.com/%" OR sync_identifier LIKE "https://raw.githubusercontent.com/%"').includes(:script_sync_type)
	end

	def webhook
		user = User.find(params[:user_id])

		# using the secret, see if this is good
		body = request.body.read
		if user.webhook_secret.nil? or request.headers['X-Hub-Signature'] != ('sha1=' + OpenSSL::HMAC.hexdigest(HMAC_DIGEST, user.webhook_secret, body))
			render :nothing => true, :status => 403
			return
		end

		if request.headers['X-GitHub-Event'] == 'ping'
			render :json => {:message => 'Webhook successfully configured.'}
			return
		end

		if request.headers['X-GitHub-Event'] != 'push'
			render :nothing => true, :status => 406
			return
		end

		if params[:commits].nil?
			render :json => {:message => 'No commits found in this push.'}
			return
		end

		# construct the raw URLs from the provided info. raw URLs are in the format:
		# (repository url)/raw/(branch)/(path) OR
		# https://raw.githubusercontent.com/(user)/(repo)/(branch)/(path)
		base_paths = [
			params[:repository][:url] + '/raw/' + params[:ref].split('/').last + '/', 'https://raw.githubusercontent.com/' + params[:repository][:url].split('/')[3..4].join('/') + '/' + params[:ref].split('/').last + '/'
		]

		changed_urls = {}
		params[:commits].each do |c|
			# there's also "added" and "deleted", but I don't think there's a case for syncing when those happen
			# rails seems to set modified to nil instead of empty
			if !c[:modified].nil?
				c[:modified].each do |m|
					base_paths.each do |bp|
						url = bp + self.class.urlify_webhook_path_segment(m)
						if !changed_urls.has_key?(url)
							changed_urls[url] = []
						end
						changed_urls[url] << c[:message]
					end
				end
			end
		end

		scripts_and_messages = self.class.get_synced_scripts(user, changed_urls)

		changed_script_urls = []
		scripts_and_messages.each do |s, messages|
			changed_script_urls << script_url(s, :only_path => false)
			# update sync type to webhook, now that we know this script is affected by it
			if s.script_sync_type_id != 3
				s.script_sync_type_id = 3
				s.save(:validate => false)
			end

			# GitHub's raw server caches things for up to 5 minutes. We also want to let the webhook request complete asynchronously anyway.
			ScriptImporter::ScriptSyncer.delay(run_at: 5.minutes.from_now).sync(s, 'Synced from GitHub - ' + messages.join(' - '))
		end

		render :json => {:affected_scripts => changed_script_urls}
	end

	def edit_sign_in
	end

	def update_password
		current_user.password = params[:password]
		current_user.password_confirmation = params[:password_confirmation]
		# prevent empty and invalid passwords
		if !current_user.valid? or params[:password].nil? or params[:password].empty?
			current_user.reload
			render :edit_sign_in
			return
		end
		current_user.save!
		# password changed, have to sign in again
		sign_in current_user, :bypass => true
		flash[:notice] = t('users.password_updated')
		redirect_to user_edit_sign_in_path
	end

	def remove_password
		if current_user.identities.empty?
			flash[:notice] = t('users.cant_remove_password')
			redirect_to user_edit_sign_in_path
			return
		end
		current_user.encrypted_password = nil
		current_user.save!
		# password changed, have to sign in again
		sign_in current_user, :bypass => true
		flash[:notice] = t('users.password_removed')
		redirect_to user_edit_sign_in_path
	end

	def update_identity
		current_user.identities.each do |id|
			if id.provider == params[:provider]
				flash[:notice] = t('users.external_sign_in_updated', :provider => Identity.pretty_provider(id.provider))
				id.syncing = params[:syncing]
				id.save
			end
		end
		redirect_to user_edit_sign_in_path
	end

	def delete_identity
		if current_user.identities.size == 1 and current_user.encrypted_password.nil?
			flash[:notice] = t('users.cant_remove_sign_in', :provider => Identity.pretty_provider(params[:provider]))
			redirect_to user_edit_sign_in_path
			return
		end
		current_user.identities.each do |id|
			if id.provider == params[:provider]
				flash[:notice] = t('users.external_sign_in_removed', :provider => Identity.pretty_provider(id.provider))
				id.delete
			end
		end
		redirect_to user_edit_sign_in_path
	end

	def ban
		@user = User.find(params[:user_id])
	end

	def do_ban
		user = User.find(params[:user_id])
		ma_ban = ModeratorAction.new
		ma_ban.moderator = current_user
		ma_ban.user = user
		ma_ban.action = 'Ban'
		ma_ban.reason = params[:reason]
		ma_ban.save!
		user.banned = true
		user.save!
		if !params[:script_delete_type_id].blank?
			user.non_locked_scripts.each do |s|
				s.delete_reason = params[:reason]
				s.locked = true
				s.script_delete_type_id = params[:script_delete_type_id]
				s.save(:validate => false)
				ma_delete = ModeratorAction.new
				ma_delete.moderator = current_user
				ma_delete.script = s
				ma_delete.action = 'Delete'
				ma_delete.reason = params[:reason]
				ma_delete.save!
			end
		end
		redirect_to user
	end

private

	def self.get_sort(params)
		case params[:sort]
			when 'scripts'
				return "count(scripts.id) DESC, users.id"
			when 'total_installs'
				return "sum(scripts.total_installs) DESC, users.id"
			when 'created_script'
				return "max(scripts.created_at) DESC, users.id"
			when 'updated_script'
				return "max(scripts.code_updated_at) DESC, users.id"
			when 'daily_installs'
				return "sum(scripts.daily_installs) DESC, users.id"
			when 'fans'
				return "sum(scripts.fan_score) DESC, users.id"
			when 'name'
				return "users.name ASC, users.id"
			else
				params[:sort] = nil
				return "users.created_at DESC, users.id"
		end
	end

	# Returns a Hash of Script to array of commit messages. Parameters:
	#   user - user to limit the script search to
	#   urls_and_messages - a map of URL for the modified files to array of commit messages
	def self.get_synced_scripts(user, urls_and_messages)
		scripts_and_messages = {}
		return scripts_and_messages if urls_and_messages.nil? or urls_and_messages.empty?

		# find the scripts syncing from those URLs for code
		scripts = Script.not_deleted.where(:user_id => user.id).where(:sync_identifier => urls_and_messages.keys).to_a

		# find the scripts syncing from those URLs for additional info
		additional_info_script_ids = Script.not_deleted.where(:user_id => user.id).where(['localized_script_attributes.sync_identifier in (?)', urls_and_messages.keys]).includes(:localized_attributes).references(:localized_script_attributes).ids
		scripts.concat(Script.find(additional_info_script_ids).to_a)
		scripts.uniq!

		# relate each script to the commit messages
		scripts.each do |s|
			messages = []

			# sync for code
			code_messages = urls_and_messages[s.sync_identifier]
			messages.concat(code_messages) unless code_messages.nil?

			# sync for localized attributes
			s.localized_attributes.select{|la| !la.sync_identifier.nil?}.map{|la| la.sync_identifier}.uniq.each do |sync_identifier|
				messages.concat(urls_and_messages[sync_identifier]) if !urls_and_messages[sync_identifier].nil?
			end

			scripts_and_messages[s] = messages.uniq
		end

		return scripts_and_messages
	end

	# Turns a path segment from a webhook request to a URL segment
	def self.urlify_webhook_path_segment(path)
		re = Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")
		return path.split('/').map{|part| URI.escape(part, re)}.join('/')
	end

end
