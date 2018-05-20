require 'script_importer/script_syncer'
require 'uri'
require 'securerandom'
require 'git'

class UsersController < ApplicationController

	skip_before_action :verify_authenticity_token, :only => [:webhook]

	before_action :authenticate_user!, :except => [:show, :webhook, :index]
	before_action :authorize_for_moderators_only, :only => [:ban, :do_ban]

	HMAC_DIGEST = OpenSSL::Digest.new('sha1')

	def index
		@users = User
		@users = @users.where(['name like ?', "%#{params[:q]}%"]) if params[:q].present?
		@users = self.class.apply_sort(@users, sort: params[:sort], script_subset: script_subset).paginate(page: params[:page], per_page: get_per_page).load
		@user_script_counts = Script.listable(script_subset).where(user_id: @users.map(&:id)).group(:user_id).count

		@bots = 'noindex,follow' if !params[:sort].nil? || !params[:q].nil?
		@title = t('users.listing_title')
		@canonical_params = [:page, :per_page, :sort, :q]

		render layout: 'base'
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

				@scripts = (@same_user || (!current_user.nil? && current_user.moderator?)) ? @user.scripts : @user.scripts.listable_including_libraries(script_subset)
				@user_has_scripts = !@scripts.empty?
				@scripts = ScriptsController.apply_filters(@scripts, params, script_subset).paginate(per_page: 100, page: params[:page] || 1)
				@other_site_scripts = script_subset == :sleazyfork ? @user.scripts.listable(:greasyfork).count : 0

				@bots = 'noindex,follow' if !params[:sort].nil?

				@link_alternates = [
					{:url => current_path_with_params(format: :json), :type => 'application/json'},
					{:url => current_path_with_params(format: :jsonp, callback: 'callback'), :type => 'application/javascript'}
				]
				@canonical_params = [:id, :page, :per_page, :set, :site, :sort]

				render layout: 'base'
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
		if user.webhook_secret.nil? || request.headers['X-Hub-Signature'] != ('sha1=' + OpenSSL::HMAC.hexdigest(HMAC_DIGEST, user.webhook_secret, body))
			head 403
			return
		end

		if request.headers['X-GitHub-Event'] == 'ping'
			render :json => {:message => 'Webhook successfully configured.'}
			return
		end

		if request.headers['X-GitHub-Event'] != 'push'
			head 406
			return
		end

		if params[:commits].nil?
			render :json => {:message => 'No commits found in this push.'}
			return
		end

		# Get a list of changed files and the commit info that goes with them.
		# We will keep all commit messages but only the most recent commit.
		changed_files = {}
		params[:commits].each do |c|
			if !c[:modified].nil?
				c[:modified].each do |m|
					changed_files[m] ||= {}
					changed_files[m][:commit] = c[:id]
					(changed_files[m][:messages] ||= []) << c[:message]
				end
			end
		end

		# construct the raw URLs from the provided info. raw URLs are in the format:
		# (repository url)/raw/(branch)/(path) OR
		# https://raw.githubusercontent.com/(user)/(repo)/(branch)/(path)
		# This will be used to find the related scripts.
		base_paths = [
			params[:repository][:url] + '/raw/' + params[:ref].split('/').last + '/', 'https://raw.githubusercontent.com/' + params[:repository][:url].split('/')[3..4].join('/') + '/' + params[:ref].split('/').last + '/'
		]

		# Associate scripts to each file.
		changed_files.each do |filename, info|
			urls = base_paths.map do |bp|
				bp + self.class.urlify_webhook_path_segment(filename)
			end
			# Scripts syncing code to this file
			info[:scripts] = user.scripts.not_deleted.where(sync_identifier: urls)

			# Scripts syncing additional info to this file
			info[:script_attributes] = LocalizedScriptAttribute.where(sync_identifier: urls).joins(:script).where(scripts: {user_id: user.id})
		end

		# Forget about any files that changed but are not related to scripts or attributes.
		changed_files = changed_files.select{|filename, info| info[:scripts].any? || info[:script_attributes].any?}

		if changed_files.empty?
			render :json => {:affected_scripts => []} 
			return
		end

		# Get the contents of the files.
		Git.get_contents(params[:repository][:git_url], Hash[changed_files.map{|filename, info| [filename, info[:commit]]}]) do |file_path, commit, content|
			changed_files[file_path][:content] = content
		end

		# Apply the new contents to the DB.

		updated_scripts = []
		update_failed_scripts = []

		changed_files.each do |filename, info|
			contents = info[:content]
			info[:scripts].each do |script|
				# update sync type to webhook, now that we know this script is affected by it
				script.script_sync_type_id = 3
				sv = script.script_versions.build(code: contents, changelog: info[:messages].join(', '))

				# Copy previous additional infos and screenshots
				last_saved_sv = script.get_newest_saved_script_version
				script.localized_attributes_for('additional_info').each do |la|
					sv.build_localized_attribute(la)
				end
				sv.screenshots = last_saved_sv.screenshots

				sv.do_lenient_saving
				sv.calculate_all(script.description)
				script.apply_from_script_version(sv)
				if script.save
					updated_scripts << script
				else
					update_failed_scripts << script
				end
			end
			info[:script_attributes].each do |script_attribute|
				script_attribute.attribute_value = contents
				if script_attribute.save
					updated_scripts << script_attribute.script
				else
					update_failed_scripts << script_attribute.script
				end
			end
		end

		render json: {updated_scripts: updated_scripts, updated_failed: update_failed_scripts}
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
		bypass_sign_in(current_user)
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
	
	def delete_info
	  @user = current_user
	  @bots = 'noindex'
	end
	
	def delete_start
	  @user = current_user
	  @user.delete_confirmation_key = SecureRandom.hex
	  @user.delete_confirmation_expiry = 1.day.from_now
	  @user.save(validate: false)
	  UserMailer.delete_confirm(@user, site_name).deliver_now
	  flash[:notice] = t('users.delete.confirmation_email_sent')
	  redirect_to @user
	end

  def delete_confirm
    @user = current_user
    if params[:key].blank? || @user.delete_confirmation_key.blank? || params[:key] != @user.delete_confirmation_key
      @error = t('users.delete.confirmation.key_mismatch')
    elsif @user.delete_confirmation_expiry.nil? || DateTime.now > @user.delete_confirmation_expiry
      @error = t('users.delete.confirmation.request_expired')
    end
  end

  def delete_complete
    @user = current_user
    if params[:cancel].present?
      @user.update_attributes(delete_confirmation_key: nil, delete_confirmation_expiry: nil)
      flash[:notice] = t('users.delete.confirmation.cancelled')
    elsif params[:key].blank? || @user.delete_confirmation_key.blank? || params[:key] != @user.delete_confirmation_key
      flash[:alert] = t('users.delete.confirmation.key_mismatch')
    elsif @user.delete_confirmation_expiry.nil? || DateTime.now > @user.delete_confirmation_expiry
      flash[:alert] = t('users.delete.confirmation.request_expired')
    else
      @user.destroy!
      sign_out @user
      flash[:alert] = t('users.delete.confirmation.completed')
    end
    redirect_to root_path
  end

  def send_confirmation_email
    current_user.send_confirmation_instructions
    flash[:notice] = t('devise.confirmations.send_instructions')
    redirect_to user_path(current_user)
  end

private

	def self.apply_sort(finder, script_subset:, sort:)
		return finder.order({created_at: :desc}, :id) if sort.blank?
		return finder.order(:name, :id) if sort == 'name'
		finder = finder.joins("#{script_subset}_listable_scripts".to_sym).group('users.id')
		case sort
			when 'scripts'
				return finder.order('count(scripts.id) DESC, users.id')
			when 'total_installs'
				return finder.order('sum(scripts.total_installs) DESC, users.id')
			when 'created_script'
				return finder.order('max(scripts.created_at) DESC, users.id')
			when 'updated_script'
				return finder.order('max(scripts.code_updated_at) DESC, users.id')
			when 'daily_installs'
				return finder.order('sum(scripts.daily_installs) DESC, users.id')
			when 'fans'
				return finder.order('sum(scripts.fan_score) DESC, users.id')
			when 'ratings'
				return finder.order('sum(scripts.good_ratings + scripts.ok_ratings + scripts.bad_ratings) DESC, users.id')
		end
		return finder.order({created_at: :desc}, :id)
	end

	# Turns a path segment from a webhook request to a URL segment
	def self.urlify_webhook_path_segment(path)
		re = Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")
		return path.split('/').map{|part| URI.escape(part, re)}.join('/')
	end

end
