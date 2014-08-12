require 'script_importer/script_syncer'

class UsersController < ApplicationController

	skip_before_action :verify_authenticity_token, :only => [:webhook]

	before_filter :authenticate_user!, :except => [:show, :webhook]

	HMAC_DIGEST = OpenSSL::Digest::Digest.new('sha1')

	def show
		@user = User.order('scripts.name')
		# current user will display discussions
		if !current_user.nil? and current_user.id == params[:id].to_i
			@user = @user.includes(:scripts => [:discussions, :script_type])
		else
			@user = @user.includes(:scripts => :script_type)
		end
		@user = @user.find(params[:id])
		@by_sites = ScriptsController.get_top_by_sites

		@scripts = ((!current_user.nil? && current_user.id == @user.id) or (!current_user.nil? and current_user.moderator?)) ? @user.scripts : @user.scripts.listable
		@user_has_scripts = !@scripts.empty?
		@scripts = ScriptsController.apply_filters(@scripts, params)

		@bots = 'noindex,follow' if !params[:sort].nil?

		return if redirect_to_slug(@user, :id)
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
		end

		# construct the raw URLs from the provided info. raw URLs are in the format:
		# (repository url)/raw/(branch)/(path) OR
		# https://raw.githubusercontent.com/(user)/(repo)/(branch)/(path)
		base_paths = [
			params[:repository][:url] + '/raw/' + params[:ref].split('/').last + '/', 'https://raw.githubusercontent.com/' + params[:repository][:url].split('/')[3..4].join('/') + '/' + params[:ref].split('/').last + '/'
		]
		logger.error(base_paths.inspect)
		changed_urls = {}
		params[:commits].each do |c|
			# there's also "added" and "deleted", but I don't think there's a case for syncing when those happen
			# rails seems to set modified to nil instead of empty
			if !c[:modified].nil?
				c[:modified].each do |m|
					base_paths.each do |bp|
						url = bp + m
						if !changed_urls.has_key?(url)
							changed_urls[url] = []
						end
						changed_urls[url] << c[:message]
					end
				end
			end
		end

		changed_script_urls = []
		if !changed_urls.empty?
			# find the scripts syncing from those URLs
			scripts = Script.not_deleted.where(:user_id => user.id).where(:sync_identifier => changed_urls.keys).includes(:script_sync_type)

			# trigger sync on each
			scripts.each do |s|
				changed_script_urls << script_url(s, :only_path => false)
				# update sync type to webhook, now that we know this script is affected by it
				if s.script_sync_type_id != 3
					s.script_sync_type_id = 3
					s.save(:validate => false)
				end
				# sync
				# GitHub's raw server caches things for up to 5 minutes. We also want to let the webhook request complete asynchronously anyway.
				ScriptImporter::ScriptSyncer.delay(run_at: 5.minutes.from_now).sync(s, 'Synced from GitHub - ' + changed_urls[s.sync_identifier].join(' '))
			end
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

end
