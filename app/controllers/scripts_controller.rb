require 'script_importer/script_syncer'
require 'csv'
require 'fileutils'
require 'cgi'

class ScriptsController < ApplicationController

	MEMBER_AUTHOR_ACTIONS = [:sync_update, :derivatives, :update_promoted, :request_permanent_deletion, :unrequest_permanent_deletion, :update_promoted]
	MEMBER_AUTHOR_OR_MODERATOR_ACTIONS = [:delete, :do_delete, :undelete, :do_undelete, :derivatives, :admin, :update_locale]
	MEMBER_MODERATOR_ACTIONS = [:mark, :do_mark, :do_permanent_deletion, :reject_permanent_deletion]
	MEMBER_PUBLIC_ACTIONS = [:diff]
	MEMBER_PUBLIC_ACTIONS_WITH_SPECIAL_LOADING = [:show, :show_code, :user_js, :meta_js, :feedback, :install_ping, :stats, :sync_additional_info_form]

	before_action do
		case action_name.to_sym
			when *MEMBER_AUTHOR_ACTIONS
				@script = Script.find(params[:id])
				render_access_denied if current_user&.id != @script.user_id
				render_locked if @script.locked?
				@bots = 'noindex'
			when *MEMBER_AUTHOR_OR_MODERATOR_ACTIONS
				@script = Script.find(params[:id])
				render_access_denied if current_user&.id != @script.user_id && !current_user&.moderator?
				render_locked if @script.locked? && !current_user&.moderator?
				@bots = 'noindex'
			when *MEMBER_MODERATOR_ACTIONS
				if !current_user&.moderator?
					render_access_denied
					next
				end
				@script = Script.find(params[:id])
				@bots = 'noindex'
			when *MEMBER_PUBLIC_ACTIONS
				@script = Script.find(params[:id])
				check_for_deleted(@script)
			when *MEMBER_PUBLIC_ACTIONS_WITH_SPECIAL_LOADING
				# Nothing
			when *COLLECTION_PUBLIC_ACTIONS
				# Nothing
			when *COLLECTION_MODERATOR_ACTIONS
				if !current_user&.moderator?
					render_access_denied
					next
				end
				@bots = 'noindex'
			else
				raise "Unknown action #{action_name}"
		end
	end

	skip_before_action :verify_authenticity_token, :only => [:install_ping]
	protect_from_forgery :except => [:user_js, :meta_js, :show, :show_code]

	# The value a syncing additional info will have after syncing is added but before the first sync succeeds
	ADDITIONAL_INFO_SYNC_PLACEHOLDER = '(Awaiting sync)'

	include ScriptListings

	def show
		@script, @script_version = versionned_script(params[:id], params[:version])

		respond_to do |format|
			format.html {

				return if handle_wrong_url(@script, :id)

				if !params[:version].nil?
					@bots = 'noindex'
				elsif @script.unlisted?
					@bots = 'noindex,follow'
				end
				@by_sites = self.class.get_by_sites(script_subset)
				@link_alternates = [
					{:url => current_path_with_params(format: :json), :type => 'application/json'},
					{:url => current_path_with_params(format: :jsonp, callback: 'callback'), :type => 'application/javascript'}
				]
				@canonical_params = [:id, :version]
				@ad_method = choose_ad_method(@script)
			}
			format.js {
				redirect_to @script.code_url
			}
			format.json { render :json => @script.as_json(:include => :user) }
			format.jsonp { render :json => @script.as_json(:include => :user), :callback => clean_json_callback_param }
			format.user_script_meta {
				route_params = {:id => params[:id], :name => @script.name, :format => nil}
				route_params[:version] = params[:version] if !params[:version].nil?
				redirect_to meta_js_script_path(route_params)
			}
		end
	end

	def show_code
		@script, @script_version = versionned_script(params[:id], params[:version])

		# some weird safari client tries to do this
		if params[:format] == 'meta.js'
			redirect_to meta_js_script_path(params.merge({:name => @script.name, :format => nil}))
			return
		end

		return if handle_wrong_url(@script, :id)

		respond_to do |format|
			format.html {
				@highlighted_code = nil
				if params[:version].nil?
					if !@script.syntax_highlighted_code.nil?
						@highlighted_code = @script.syntax_highlighted_code.html
					end
				else
					@bots = 'noindex'
				end
				# Generate on the fly
				if @highlighted_code.nil?
					@highlighted_code = SyntaxHighlightedCode.highlight(@script_version.rewritten_code)
				end
				if @highlighted_code.nil?
					@code = @script_version.rewritten_code
				end
				@canonical_params = [:id, :version]
			}
			format.js {
				redirect_to @script.code_url
			}
			format.user_script_meta {
				route_params = {:id => params[:id], :name => @script.name, :format => nil}
				route_params[:version] = params[:version] if !params[:version].nil?
				redirect_to meta_js_script_path(route_params)
			}
		end
	end

	def feedback
		@script, @script_version = versionned_script(params[:id], params[:version])

		return if handle_wrong_url(@script, :id)

		@bots = 'noindex' if !params[:version].nil?
		@canonical_params = [:id, :version]
	end

	def user_js
		respond_to do |format|
			format.any(:html, :all, :js) {
				script_id = params[:id].to_i
				script_version_id = params[:version].to_i

				script, script_version = minimal_versionned_script(script_id, script_version_id)
				return if handle_replaced_script(script)

				user_js_code = script.script_delete_type_id == 2 ? script_version.get_blanked_code : script_version.rewritten_code

				# If the request specifies a specific version, the code will never change, so inform the manager not to check for updates.
				if params[:version].present? && !script.library?
					user_js_code = ScriptVersion.inject_meta_for_code(user_js_code, downloadURL: 'none')
				end

				# Only cache if:
				# - It's not for a specific version (as the caching does not work with query params)
				# - It's a .user.js extension (client's Accept header may not match path).
				cache_request(user_js_code) if script_version_id == 0 && request.fullpath.end_with?('.user.js')

				render body: user_js_code, content_type: 'text/javascript'
			}
			format.user_script_meta { 
				meta_js
			}
		end
	end

	def meta_js
		script_id = params[:id].to_i
		script_version_id = (params[:version] || 0).to_i

		# Bypass ActiveRecord for performance
		if script_version_id > 0
			sql = <<-EOF
				SELECT
					script_versions.id script_version_id,
					script_delete_type_id,
					scripts.replaced_by_script_id,
					script_codes.code
				FROM scripts
				JOIN script_versions on script_versions.script_id = scripts.id
				JOIN script_codes on script_versions.rewritten_script_code_id = script_codes.id
				WHERE
					scripts.id = #{Script.connection.quote(script_id)}
					AND script_versions.id = #{Script.connection.quote(script_version_id)}
				LIMIT 1
			EOF
		else
			sql = <<-EOF
				SELECT
					script_versions.id script_version_id,
					script_delete_type_id,
					scripts.replaced_by_script_id,
					script_codes.code
				FROM scripts
				JOIN script_versions on script_versions.script_id = scripts.id
				JOIN script_codes on script_versions.rewritten_script_code_id = script_codes.id
				WHERE
					scripts.id = #{Script.connection.quote(script_id)}
				ORDER BY script_versions.id DESC
				LIMIT 1
			EOF
		end
		script_info = Script.connection.select_one(sql)
		raise ActiveRecord::RecordNotFound if script_info.nil?

		if !script_info['replaced_by_script_id'].nil? && script_info['script_delete_type_id'] == 1
			redirect_to(id: script_info['replaced_by_script_id'], status: 301)
			return
		end

		# Strip out some thing that could contain a lot of data (data: URIs). get_blanked_code already does this.
		meta_js_code = script_info['script_delete_type_id'] == 2 ? ScriptVersion.get_blanked_code(script_info['code']) : ScriptVersion.inject_meta_for_code(ScriptVersion.get_meta_block(script_info['code']), {icon: nil, resource: nil})

		# Only cache if:
		# - It's not for a specific version (as the caching does not work with query params)
		# - It's a .meta.js extension (client's Accept header may not match path).
		cache_request(meta_js_code) if script_version_id == 0 && request.fullpath.end_with?('.meta.js')

		render body: meta_js_code, content_type: 'text/x-userscript-meta'
	end

	def install_ping
		# verify for CSRF, but do it in a way that avoids an exception. Prevents monitoring from going nuts.
		if !verified_request?
			head 422
			return
		end
		ip, script_id = ScriptsController.per_user_stat_params(request, params)
		if ip.nil? || script_id.nil?
			head 422
			return
		end
		Script.record_install(script_id, ip)
		head 204
	end

	def diff
		return if handle_wrong_url(@script, :id)

		versions = [params[:v1].to_i, params[:v2].to_i]
		@old_version = ScriptVersion.find(versions.min)
		@new_version = ScriptVersion.find(versions.max)
		if @old_version.nil? or @new_version.nil? or @old_version.script_id != @script.id or @new_version.script_id != @script.id
			@text = 'Invalid versions provided.'
			render 'home/error', status: 400, layout: 'application'
			return
		end
		@context = 3
		if !params[:context].nil? and params[:context].to_i.between?(0, 10000)
			@context = params[:context].to_i
		end
		diff_options = ["-U #{@context}"]
		diff_options << "-w" if !params[:w].nil? && params[:w] == '1'
		@diff = Diffy::Diff.new(@old_version.code, @new_version.code, :include_plus_and_minus_in_html => true, :include_diff_info => true, :diff => diff_options).to_s(:html).html_safe
		@bots = 'noindex'
		@canonical_params = [:id, :v1, :v2, :context, :w]
	end

	def sync_update
		if !params['stop-syncing'].nil?
			@script.script_sync_type_id = nil
			@script.script_sync_source_id = nil
			@script.last_attempted_sync_date = nil
			@script.last_successful_sync_date = nil
			@script.sync_identifier = nil
			@script.sync_error = nil
			@script.localized_attributes_for('additional_info').each {|la|
				la.sync_source_id = nil
				la.sync_identifier = nil
			}
			@script.save(:validate => false)
			flash[:notice] = 'Script sync turned off.'
			redirect_to @script
			return
		end

		@script.assign_attributes(params.require(:script).permit(:script_sync_type_id, :sync_identifier))
		if @script.script_sync_source_id.nil?
			@script.script_sync_source_id = ScriptImporter::ScriptSyncer.get_sync_source_id_for_url(params[:sync_identifier])
		end

		# additional info syncs. and new ones and update existing ones to add/update sync_identifiers
		if params['additional_info_sync']
			current_additional_infos = @script.localized_attributes_for('additional_info')
			# keep track of the ones we see - ones we don't will be unsynced or deleted
			unused_additional_infos = current_additional_infos.dup
			params['additional_info_sync'].each do |index, sync_params|
				# if it's blank it will be ignored (if new) or no longer synced (if existing)
				form_is_blank = (sync_params['attribute_default'] != 'true' && sync_params['locale'].nil?) || sync_params['sync_identifier'].blank?
				existing = current_additional_infos.find{|la| (la.attribute_default && sync_params['attribute_default'] == 'true') || la.locale_id == sync_params['locale'].to_i}
				if existing.nil?
					next if form_is_blank
					attribute_default = (sync_params['attribute_default'] == 'true')
					@script.localized_attributes.build(:attribute_key => 'additional_info', :sync_identifier => sync_params['sync_identifier'], :value_markup => sync_params['value_markup'], :sync_source_id => 1, :locale_id => attribute_default ? @script.locale_id : sync_params['locale'], :attribute_value => ADDITIONAL_INFO_SYNC_PLACEHOLDER, :attribute_default => attribute_default)
				else
					if !form_is_blank
						unused_additional_infos.delete(existing)
						existing.sync_identifier = sync_params['sync_identifier']
						existing.sync_source_id = 1
						existing.value_markup = sync_params['value_markup']
					end
				end
			end
			unused_additional_infos.each do |la|
				# Keep the existing if it had anything but the placeholder
				if la.attribute_value == ADDITIONAL_INFO_SYNC_PLACEHOLDER
					la.mark_for_destruction
				else
					la.sync_identifier = nil
					la.sync_source_id = nil
				end
			end
		end

		save_record = params[:preview].nil? && params['add-synced-additional-info'].nil?

		# preview for people with JS disabled
		if !params[:preview].nil?
			@preview = {}
			preview_params = params['additional_info_sync'][params[:preview]]
			begin
				text = ScriptImporter::BaseScriptImporter.download(preview_params[:sync_identifier])
				@preview[params[:preview].to_i] = view_context.format_user_text(text, preview_params[:value_markup])
			rescue ArgumentError => ex
				@preview[params[:preview].to_i] = ex.to_s
			end
		end

		# add sync localized additional info for people with JS disabled
		if !params['add-synced-additional-info'].nil?
			@script.localized_attributes.build({:attribute_key => 'additional_info', :attribute_default => false})
		end

		if !save_record || !@script.save
			ensure_default_additional_info(@script, current_user.preferred_markup)
			render :admin
			return
		end
		if !params['update-and-sync'].nil?
			case ScriptImporter::ScriptSyncer.sync(@script)
				when :success
					flash[:notice] = 'Script successfully synced.'
				when :unchanged
					flash[:notice] = 'Script successfully synced, but no changes found.'
				when :failure
					flash[:notice] = "Script sync failed - #{@script.sync_error}."
			end
		end
		redirect_to @script
	end

	def delete
		if !@script.deleted?
			@other_scripts = Script.where(:user => @script.user).where(:locked => false).where(['id != ?', @script.id]).count
		end
	end

	def do_delete
		# Grab those vars...
		delete

		# Handle replaced by
		replaced_by = get_script_from_input(params[:replaced_by_script_id])
		case replaced_by
			when :non_gf_url
				@script.errors.add(:replaced_by_script_id, I18n.t('errors.messages.must_be_greasy_fork_script', site_name: site_name))
				render :delete
				return
			when :non_script_url
				@script.errors.add(:replaced_by_script_id, :must_be_greasy_fork_script)
				render :delete
				return
			when :not_found
				@script.errors.add(:replaced_by_script_id, :not_found)
				render :delete
				return
			when :deleted
				@script.errors.add(:replaced_by_script_id, :cannot_be_deleted_reference)
				render :delete
				return
		end

		if replaced_by && @script.id == replaced_by.id
			@script.errors.add(:replaced_by_script_id, :cannot_be_self_reference)
			render :delete
			return
		end

		@script.replaced_by_script = replaced_by

		if current_user.moderator? && current_user != @script.user
			@script.locked = params[:locked].nil? ? false : params[:locked]
			ma = ModeratorAction.new
			ma.moderator = current_user
			ma.script = @script
			ma.action = @script.locked ? 'Delete and lock' : 'Delete'
			ma.reason = params[:reason]
			@script.delete_reason = params[:reason]
			ma.save!
			if params[:banned]
				ma_ban = ModeratorAction.new
				ma_ban.moderator = current_user
				ma_ban.user = @script.user
				ma_ban.action = 'Ban'
				ma_ban.reason = params[:reason]
				ma_ban.save!
				@script.user.banned = true
				@script.user.save!
			end
		end
		@script.permanent_deletion_request_date = nil if @script.locked
		@script.script_delete_type_id = params[:script_delete_type_id]
		@script.save(:validate => false)
		redirect_to @script
	end

	def do_undelete
		if current_user.moderator? && current_user != @script.user
			ma = ModeratorAction.new
			ma.moderator = current_user
			ma.script = @script
			ma.action = 'Undelete'
			ma.reason = params[:reason]
			ma.save!
			@script.locked = false
			if @script.user.banned and params[:unbanned]
				ma_ban = ModeratorAction.new
				ma_ban.moderator = current_user
				ma_ban.user = @script.user
				ma_ban.action = 'Unban'
				ma_ban.reason = params[:reason]
				ma_ban.save!
				@script.user.banned = false
				@script.user.save!
			end
		end
		@script.script_delete_type_id = nil
		@script.replaced_by_script_id = nil
		@script.delete_reason = nil
		@script.permanent_deletion_request_date = nil
		@script.save(:validate => false)
		redirect_to @script
	end

	def request_permanent_deletion
		if @script.locked
			flash[:notice] = I18n.t('scripts.delete_permanently_rejected_locked')
			redirect_to root_path
			return
		end
		if @script.immediate_deletion_allowed?
			@script.destroy!
			flash[:notice] = I18n.t('scripts.delete_permanently_notice_immediate')
			redirect_to root_path
			return
		end
		@script.permanent_deletion_request_date = DateTime.now
		@script.save(validate: false)
		flash[:notice] = I18n.t('scripts.delete_permanently_notice')
		redirect_to @script
	end

	def unrequest_permanent_deletion
		@script.permanent_deletion_request_date = nil
		@script.save(validate: false)
		flash[:notice] = I18n.t('scripts.cancel_delete_permanently_notice')
		redirect_to @script
	end

	def do_permanent_deletion
		Script.transaction do
			@script.destroy!
			ma = ModeratorAction.new
			ma.moderator = current_user
			ma.script = @script
			ma.action = 'Permanent deletion'
			ma.reason = 'Author request'
			ma.save!
		end
		flash[:notice] = I18n.t('scripts.delete_permanently_notice_immediate')
		redirect_to root_path
	end

	def reject_permanent_deletion
		Script.transaction do
			ma = ModeratorAction.new
			ma.moderator = current_user
			ma.script = @script
			ma.action = 'Permanent deletion denied'
			ma.reason = params[:reason]
			ma.save!
			@script.permanent_deletion_request_date = nil
			@script.save(validate: false)
		end
		flash[:notice] = 'Permanent deletion request rejected.'
		redirect_to script
	end

	def mark
	end

	def do_mark
		ma = ModeratorAction.new
		ma.moderator = current_user
		ma.script = @script
		ma.reason = params[:reason]

		case params[:mark]
			when 'adult'
				@script.sensitive = true
				ma.action = 'Mark as adult content'
			when 'not_adult'
				@script.sensitive = false
				@script.not_adult_content_self_report_date = nil
				ma.action = 'Mark as not adult content'
			when 'clear_not_adult'
				@script.not_adult_content_self_report_date = nil
			else
				@text = "Can't do that!"
				render 'home/error', status: 406, layout: 'application'
				return
		end

		ma.save! if !ma.action.nil?

		@script.save!
		flash[:notice] = 'Script updated.'
		redirect_to @script
	end

	def stats
		@script, @script_version = versionned_script(params[:id], params[:version])

		return if handle_wrong_url(@script, :id)

		install_values = Hash[Script.connection.select_rows("SELECT install_date, installs FROM install_counts where script_id = #{@script.id}")]
		daily_install_values = Hash[Script.connection.select_rows("SELECT DATE(install_date) d, COUNT(*) FROM daily_install_counts where script_id = #{@script.id} GROUP BY d")]
		update_check_values = Hash[Script.connection.select_rows("SELECT update_check_date, update_checks FROM update_check_counts where script_id = #{@script.id}")]
		@stats = {}
		update_check_start_date = Date.parse('2014-10-23')
		(@script.created_at.to_date..Time.now.utc.to_date).each do |d|
			stat = {}
			stat[:installs] = install_values[d] || daily_install_values[d] || 0
			# this stat not available before that date
			stat[:update_checks] = d >= update_check_start_date ? (update_check_values[d] || 0) : nil
			@stats[d] = stat
		end
		respond_to do |format|
			format.html {
				@canonical_params = [:id, :version]
			}
			format.csv {
				data = CSV.generate do |csv|
					csv << ['Date', 'Installs', 'Update checks']
					@stats.each do |d, stat|
						csv << [d, stat.values].flatten
					end
				end
				render :plain => data
				response.content_type = 'text/csv'
			}
			format.json {
				render :json => @stats
			}
		end
	end

	def derivatives
		return if redirect_to_slug(@script, :id)

		similar_names = {}
		Script.listable(script_subset).includes(:localized_names).where(['user_id != ?', @script.user_id]).each do |other_script|
			other_script.localized_names.each do |ln|
				dist = Levenshtein.normalized_distance(@script.name, ln.attribute_value)
				similar_names[other_script.id] = dist if similar_names[other_script.id].nil? or dist < similar_names[other_script.id]
			end
		end
		similar_names = similar_names.sort_by{|k, v| v}.take(10)
		@similar_name_scripts = similar_names.map{|a| Script.includes([:user, :license]).find(a[0])}

		@same_namespaces = []
		@same_namespaces = Script.listable(script_subset).where(['user_id != ?', @script.user_id]).where(:namespace => @script.namespace).includes([:user, :license]) if !@script.namespace.nil?

		# Disabled until we can find something that can handle current volumes.
		# only duplications containing listable scripts by others
		# @code_duplications = @script.cpd_duplications.includes(:cpd_duplication_scripts => {:script => :user}).select {|dup| dup.cpd_duplication_scripts.any?{|cpdds| cpdds.script.user_id != @script.user_id && cpdds.script.listable?}}.uniq

		@canonical_params = [:id]
	end

	def admin
		# For sync section
		@script.script_sync_type_id = 1 if @script.script_sync_source_id.nil?
		@script.localized_attributes.build({:attribute_key => 'additional_info', :attribute_default => true}) if @script.localized_attributes_for('additional_info').empty?
	end

	def update_promoted
		promoted_script = get_script_from_input(params[:promoted_script_id])
		case promoted_script
			when :non_gf_url
				@script.errors.add(:promoted_script_id, I18n.t('errors.messages.must_be_greasy_fork_script', site_name: site_name))
				render :admin
				return
			when :non_script_url
				@script.errors.add(:promoted_script_id, :must_be_greasy_fork_script)
				render :admin
				return
			when :not_found
				@script.errors.add(:promoted_script_id, :not_found)
				render :admin
				return
			when :deleted
				@script.errors.add(:promoted_script_id, :cannot_be_deleted_reference)
				render :admin
				return
		end

		if promoted_script == @script
			@script.errors.add(:promoted_script_id, :cannot_be_self_reference)
			render :admin
			return
		end

		if @script.sensitive? != promoted_script.sensitive?
			@script.errors.add(:promoted_script_id, :cannot_be_used_with_this_script)
			render :admin
			return
		end

		@script.promoted_script = promoted_script
		@script.save!

		flash[:notice] = I18n.t('scripts.updated')
		redirect_to admin_script_path(@script)
	end

	def sync_additional_info_form
		render :partial => 'sync_additional_info', :locals => {:la => LocalizedScriptAttribute.new({:attribute_default => false}), :index => params[:index].to_i}
	end

	def update_locale
		update_params = params.require(:script).permit(:locale_id)
		if @script.update_attributes(update_params)
			if @script.user != current_user
				ModeratorAction.create!(script: @script, moderator: current_user, action: 'Update locale', reason: "Changed to #{@script.locale.code}#{update_params[:locale_id].blank? ? ' (auto-detected)' : ''}")
			end
			flash[:notice] = I18n.t('scripts.updated')
			redirect_to admin_script_path(@script)
			return
		end

		render :admin
	end

private

	# Returns a hash, key: site name, value: hash with keys installs, scripts
	def self.get_by_sites(script_subset, cache_options = {})
		return cache_with_log("scripts/get_by_sites#{script_subset}", cache_options) do
			subset_clause = case script_subset
				when :greasyfork
					"AND `sensitive` = false"
				when :sleazyfork
					"AND `sensitive` = true"
				else
					""
			end
			sql =<<-EOF
				SELECT
					text, SUM(daily_installs) install_count, COUNT(s.id) script_count
				FROM script_applies_tos
				JOIN scripts s ON script_id = s.id
				JOIN site_applications on site_applications.id = site_application_id
				WHERE
					domain
					AND script_type_id = 1
					AND script_delete_type_id IS NULL
					AND !tld_extra
					#{subset_clause}
				GROUP BY text
				ORDER BY text
			EOF
			Rails.logger.warn("Loading by_sites") if Greasyfork::Application.config.log_cache_misses
			by_sites = Script.connection.select_rows(sql)
			Rails.logger.warn("Loading all_sites") if Greasyfork::Application.config.log_cache_misses
			all_sites = get_all_sites_count.values.to_a
			Rails.logger.warn("Combining by_sites and all_sites") if Greasyfork::Application.config.log_cache_misses
			# combine with "All sites" number
			a = ([[nil] + all_sites] + by_sites)
			Hash[a.map {|key, install_count, script_count| [key, {:installs => install_count.to_i, :scripts => script_count.to_i}]}]
		end
	end

	def self.get_all_sites_count
		sql =<<-EOF
			SELECT
				sum(daily_installs) install_count, count(distinct scripts.id) script_count
			FROM scripts
			WHERE
				script_type_id = 1
				AND script_delete_type_id is null
				AND NOT EXISTS (SELECT * FROM script_applies_tos WHERE script_id = scripts.id)
		EOF
		return Script.connection.select_all(sql).first
	end

	# Returns IP and script ID. They will be nil if not valid.
	def self.per_user_stat_params(r, p)
		# Get IP in a way that avoids an exception. Prevents monitoring from going nuts.
		ip = nil
		begin
			ip = r.remote_ip
		rescue ActionDispatch::RemoteIp::IpSpoofAttackError => ex
			# do nothing, ip remains nil
		end
		# strip the slug
		script_id = p[:id].to_i.to_s
		return [ip, script_id]
	end

	def handle_replaced_script(script)
		if !script.replaced_by_script_id.nil? && script.script_delete_type_id == 1
			redirect_to(id: script.replaced_by_script_id, status: 301)
			return true
		end
		return false
	end

	def get_script_from_input(v)
		return nil if v.blank?

		replaced_by = nil
		script_id = nil
		# Is it an ID?
		if v.to_i != 0
			script_id = v.to_i
		# A non-GF URL?
		elsif !v.start_with?('https://greasyfork.org/')
			return :non_gf_url
		# A GF URL?
		else
			url_match = /\/scripts\/([0-9]+)(\-|$)/.match(v)
			return :non_script_url if url_match.nil?
			script_id = url_match[1]
		end

		# Validate it's a good replacement
		begin
			script = Script.find(script_id)
		rescue ActiveRecord::RecordNotFound
			return :not_found
		end

		return :deleted unless script.script_delete_type_id.nil?

		return script
	end

	def cache_request(response_body)
		# Cache dir + request path without leading slash. Ensure it's actually under the cache dir to prevent
		# directory traversal.
		cache_request_portion = CGI::unescape(request.fullpath[1..-1])
		cache_path = Rails.application.config.script_page_cache_directory.join(cache_request_portion).cleanpath
		if cache_path.to_s.start_with?(Rails.application.config.script_page_cache_directory.to_s)
			FileUtils.mkdir_p(cache_path.parent)
			File.write(cache_path, response_body)
		end
	end

	def handle_wrong_url(resource, id_param_name)
		raise ActiveRecord::RecordNotFound if resource.nil?
		return true if handle_wrong_site(resource)
		return true if redirect_to_slug(resource, id_param_name)
		return false
	end

end
