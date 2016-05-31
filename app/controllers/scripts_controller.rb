require 'script_importer/script_syncer'
require 'csv'

class ScriptsController < ApplicationController
	layout 'application', :except => [:show, :show_code, :feedback, :diff, :sync, :sync_update, :delete, :do_delete, :stats, :derivatives, :mark, :do_mark]

	before_filter :authorize_by_script_id, :only => [:sync, :sync_update, :request_permanent_deletion, :unrequest_permanent_deletion]
	before_filter :authorize_by_script_id_or_moderator, :only => [:delete, :do_delete, :undelete, :do_undelete, :derivatives]
	before_filter :check_for_locked_by_script_id, :only => [:sync, :sync_update, :delete, :do_delete, :undelete, :do_undelete, :request_permanent_deletion, :unrequest_permanent_deletion]
	before_filter :check_for_deleted_by_id, :only => [:show]
	before_filter :check_for_deleted_by_script_id, :only => [:show_code, :feedback, :install_ping, :diff]
	before_filter :authorize_for_moderators_only, :only => [:minified, :mark, :do_mark, :reported_not_adult, :do_permanent_deletion, :reject_permanent_deletion, :requested_permanent_deletion]

	skip_before_action :verify_authenticity_token, :only => [:install_ping]
	protect_from_forgery :except => [:user_js, :meta_js, :show, :show_code]

	# The value a syncing additional info will have after syncing is added but before the first sync succeeds
	ADDITIONAL_INFO_SYNC_PLACEHOLDER = '(Awaiting sync)'

	#########################
	# Collections
	#########################

	def index
		@scripts = Script.listable(script_subset).includes({:user => {}, :script_type => {}, :localized_attributes => :locale, :script_delete_type => {}}).paginate(:page => params[:page], :per_page => get_per_page)
		@scripts = self.class.apply_filters(@scripts, params, script_subset)

		respond_to do |format|
			format.html {
				if !params[:set].nil?
					@set = ScriptSet.find(params[:set])
				end
				@by_sites = self.class.get_top_by_sites(script_subset)

				@bots = 'noindex,follow' if !params[:sort].nil?
				@link_alternates = get_listing_link_alternatives

				if !params[:set].nil?
					if @set.favorite
						@title = t('scripts.listing_title_for_favorites', :set_name => @set.display_name, :user_name => @set.user.name)
					else
						@title = @set.display_name
						@description = @set.description
					end
				elsif params[:site] == '*' and !@scripts.empty?
					@title = t('scripts.listing_title_all_sites')
					@description = t('scripts.listing_description_all_sites')
				elsif !params[:site].nil? and !@scripts.empty?
					@title = t('scripts.listing_title_for_site', :site => params[:site])
					@description = t('scripts.listing_description_for_site', :site => params[:site])
				else
					@title = t('scripts.listing_title_generic')
					@description = t('scripts.listing_description_generic')
				end
				@canonical_params = [:page, :per_page, :set, :site, :sort]
			}
			format.atom
			format.json {
				render :json => params[:meta] == '1' ? {count: @scripts.count} : @scripts.as_json(:include => :user)
			}
			format.jsonp {
				render :json => params[:meta] == '1' ? {count: @scripts.count} : @scripts.as_json(:include => :user), :callback => clean_json_callback_param
			}
		end
	end

	def by_site
		@by_sites = self.class.get_by_sites(script_subset)
	end

	def search
		if params[:q].nil? || params[:q].empty?
			redirect_to scripts_path
			return
		end

		with = case script_subset
			when :greasyfork
				{sensitive: false}
			when :sleazyfork
				{sensitive: true}
			else
				{}
		end

		begin
			# :ranker => "expr('top(user_weight)')" means that it will be sorted on the top ranking match rather than
			# an aggregate of all matches. In other words, something matching on "name" will be tied with everything
			# else matching on "name".
			@scripts = Script.search params[:q], match_mode: :extended, with: with, page: params[:page], per_page: get_per_page, order: self.class.get_sort(params, true), populate: true, includes: [:script_type, localized_attributes: :locale], select: '*, weight() myweight', ranker: "expr('top(user_weight)')"
			# make it run now so we can catch syntax errors
			@scripts.empty?
		rescue ThinkingSphinx::SyntaxError => e
			flash[:alert] = "Invalid search query - '#{params[:q]}'."
			# back to the main listing
			redirect_to scripts_path
			return
		end

		@bots = 'noindex,follow'
		@title = t('scripts.listing_title_for_search', :search_string => params[:q])
		# filters and such have been handled above
		render_script_list(@scripts, {skip_filters: true})
	end

	def libraries
		@scripts = Script.libraries(script_subset)
	end

	def reported
		@bots = 'noindex'
		@scripts = Script.reported
	end

	def reported_not_adult
		@bots = 'noindex'
		@scripts = Script.reported_not_adult
		render :reported
	end

	def requested_permanent_deletion
		@bots = 'noindex'
		@scripts = Script.requested_permanent_deletion
		render :reported
	end

	def minified
		@bots = 'noindex'
		@scripts = []
		Script.order(self.class.get_sort(params)).where(:locked => false).each do |script|
			sv = script.get_newest_saved_script_version
			@scripts << script if sv.appears_minified
		end
		@paginate = false
		@title = "Potentially minified user scripts on Greasy Fork"
		render :action => 'index'
	end

	def redistributable
		@title = t('scripts.redistributable_title')
		@page_description = t('scripts.redistributable_page_description')
		@bots = 'noindex,follow'
		render_script_list(Script.redistributable(script_subset))
	end

	def code_search
		@bots = 'noindex,follow'
		if params[:c].nil? or params[:c].empty?
			return
		end

		# get latest version for each script
		script_version_ids = Script.connection.select_values("SELECT MAX(id) FROM script_versions GROUP BY script_id")

		# check the code for the search text
		# using the escape character doesn't seem to work, yet it works from the command line. so choose something unlikely to be used as our escape character
		script_ids = Script.connection.select_values("SELECT DISTINCT script_id FROM script_versions JOIN script_codes ON rewritten_script_code_id = script_codes.id WHERE script_versions.id IN (#{script_version_ids.join(',')}) AND code LIKE '%#{Script.connection.quote_string(params[:c].gsub('É', 'ÉÉ').gsub('%', 'É%').gsub('_', 'É_'))}%' ESCAPE 'É' LIMIT 100")
		@scripts = Script.order(self.class.get_sort(params)).where(:locked => false).includes([:user, :script_type, :script_delete_type]).where(:id => script_ids)
		@paginate = false
		@title = t('scripts.listing_title_for_code_search', :search_string => params[:c])
		@canonical_params = [:c, :sort]
		render :action => 'index'
	end

	#########################
	# Single resource
	#########################

	def show
		@script, @script_version = versionned_script(params[:id], params[:version])

		respond_to do |format|
			format.html {

				return if handle_wrong_site(@script)
				return if redirect_to_slug(@script, :id)

				if !params[:version].nil?
					@bots = 'noindex'
				elsif @script.unlisted?
					@bots = 'noindex,follow'
				end
				@by_sites = self.class.get_by_sites(script_subset)
				@link_alternates = [
					{:url => url_for(params.merge({:only_path => true, :format => :json})), :type => 'application/json'},
					{:url => url_for(params.merge({:only_path => true, :format => :jsonp, :callback => 'callback'})), :type => 'application/javascript'}
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
				route_params = {:script_id => params[:id], :name => @script.name, :format => nil}
				route_params[:version] = params[:version] if !params[:version].nil?
				redirect_to script_meta_js_path(route_params)
			}
		end
	end

	def show_code
		@script, @script_version = versionned_script(params[:script_id], params[:version])

		# some weird safari client tries to do this
		if params[:format] == 'meta.js'
			redirect_to script_meta_js_path(params.merge({:name => @script.name, :format => nil}))
			return
		end

		return if handle_wrong_site(@script)
		return if redirect_to_slug(@script, :script_id)

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
				@canonical_params = [:script_id, :version]
			}
			format.js {
				redirect_to @script.code_url
			}
			format.user_script_meta {
				render_meta_js(@script, @script_version)
			}
		end
	end

	def feedback
		@script, @script_version = versionned_script(params[:script_id], params[:version])

		return if handle_wrong_site(@script)
		return if redirect_to_slug(@script, :script_id)

		@bots = 'noindex' if !params[:version].nil?
		@canonical_params = [:script_id, :version]
	end

	def user_js
		script, script_version = minimal_versionned_script(params[:script_id], params[:version])
		return if handle_replaced_script(script)
		respond_to do |format|
			format.any(:html, :all, :js) {
				render :text => script.script_delete_type_id == 2 ? script_version.get_blanked_code : script_version.rewritten_code, :content_type => 'text/javascript'
			}
			format.user_script_meta { 
				render_meta_js(script, script_version)
			}
		end
	end

	def meta_js
		script, script_version = minimal_versionned_script(params[:script_id], params[:version])
		return if handle_replaced_script(script)
		render_meta_js(script, script_version)
	end

	def install_ping
		# verify for CSRF, but do it in a way that avoids an exception. Prevents monitoring from going nuts.
		if !verified_request?
			render :nothing => true, :status => 422
			return
		end
		ip, script_id = ScriptsController.per_user_stat_params(request, params)
		if ip.nil? || script_id.nil?
			render :nothing => true, :status => 422
			return
		end
		Script.record_install(script_id, ip)
		render :nothing => true, :status => 204
	end

	def diff
		@script = Script.find(params[:script_id])

		return if handle_wrong_site(@script)
		return if redirect_to_slug(@script, :script_id)

		versions = [params[:v1].to_i, params[:v2].to_i]
		@old_version = ScriptVersion.find(versions.min)
		@new_version = ScriptVersion.find(versions.max)
		if @old_version.nil? or @new_version.nil? or @old_version.script_id != @script.id or @new_version.script_id != @script.id
			render :text => 'Invalid versions provided.', :status => 400, :layout => true
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
		@canonical_params = [:script_id, :v1, :v2, :context, :w]
	end

	def sync
		@script = Script.find(params[:script_id])
		return if redirect_to_slug(@script, :script_id)
		@script.script_sync_type_id = 1 if @script.script_sync_source_id.nil?
		@script.localized_attributes.build({:attribute_key => 'additional_info', :attribute_default => true}) if @script.localized_attributes_for('additional_info').empty?
		@bots = 'noindex'
	end

	def sync_update
		@script = Script.find(params[:script_id])
		@bots = 'noindex'

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
			render :sync
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
		@script = Script.find(params[:script_id])
		if !@script.deleted?
			@other_scripts = Script.where(:user => @script.user).where(:locked => false).where(['id != ?', @script.id]).count
		end
		@bots = 'noindex'
	end

	def do_delete
		# Grab those vars...
		delete

		# Handle replaced by
		if !params[:replaced_by_script_id].nil? && !params[:replaced_by_script_id].blank?
			replaced_by = nil
			script_id = nil
			# Is it an ID?
			if params[:replaced_by_script_id].to_i != 0
				script_id = params[:replaced_by_script_id].to_i
			# A non-GF URL?
			elsif !params[:replaced_by_script_id].start_with?('https://greasyfork.org/')
				@script.errors.add(:replaced_by_script_id, :must_be_greasy_fork_script)
				render :delete
				return
			# A GF URL?
			else
				url_match = /\/scripts\/([0-9]+)(\-|$)/.match(params[:replaced_by_script_id])
				if url_match.nil?
					@script.errors.add(:replaced_by_script_id, :must_be_greasy_fork_script)
					render :delete
					return
				end
				script_id = url_match[1]
			end

			# Validate it's a good replacement
			begin
				replaced_by = Script.find(script_id)
			rescue ActiveRecord::RecordNotFound
				@script.errors.add(:replaced_by_script_id, :not_found)
				render :delete
				return
			end

			if @script.id == replaced_by.id
				@script.errors.add(:replaced_by_script_id, :cannot_be_self_reference)
				render :delete
				return
			end
			if !replaced_by.script_delete_type_id.nil?
				@script.errors.add(:replaced_by_script_id, :cannot_be_deleted_reference)
				render :delete
				return
			end
			@script.replaced_by_script = replaced_by
		end

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
		@bots = 'noindex'
		script = Script.find(params[:script_id])
		if current_user.moderator? && current_user != script.user
			ma = ModeratorAction.new
			ma.moderator = current_user
			ma.script = script
			ma.action = 'Undelete'
			ma.reason = params[:reason]
			ma.save!
			script.locked = false
			if script.user.banned and params[:unbanned]
				ma_ban = ModeratorAction.new
				ma_ban.moderator = current_user
				ma_ban.user = script.user
				ma_ban.action = 'Unban'
				ma_ban.reason = params[:reason]
				ma_ban.save!
				script.user.banned = false
				script.user.save!
			end
		end
		script.script_delete_type_id = nil
		script.replaced_by_script_id = nil
		script.delete_reason = nil
		script.permanent_deletion_request_date = nil
		script.save(:validate => false)
		redirect_to script
	end

	def request_permanent_deletion
		script = Script.find(params[:script_id])
		if script.locked
			flash[:notice] = I18n.t('scripts.delete_permanently_rejected_locked')
			redirect_to root_path
			return
		end
		if script.immediate_deletion_allowed?
			script.destroy!
			flash[:notice] = I18n.t('scripts.delete_permanently_notice_immediate')
			redirect_to root_path
			return
		end
		script.permanent_deletion_request_date = DateTime.now
		script.save(validate: false)
		flash[:notice] = I18n.t('scripts.delete_permanently_notice')
		redirect_to script
	end

	def unrequest_permanent_deletion
		script = Script.find(params[:script_id])
		script.permanent_deletion_request_date = nil
		script.save(validate: false)
		flash[:notice] = I18n.t('scripts.cancel_delete_permanently_notice')
		redirect_to script
	end

	def do_permanent_deletion
		script = Script.find(params[:script_id])
		Script.transaction do
			script.destroy!
			ma = ModeratorAction.new
			ma.moderator = current_user
			ma.script = script
			ma.action = 'Permanent deletion'
			ma.reason = 'Author request'
			ma.save!
		end
		flash[:notice] = I18n.t('scripts.delete_permanently_notice_immediate')
		redirect_to root_path
	end

	def reject_permanent_deletion
		script = Script.find(params[:script_id])
		Script.transaction do
			ma = ModeratorAction.new
			ma.moderator = current_user
			ma.script = script
			ma.action = 'Permanent deletion denied'
			ma.reason = params[:reason]
			ma.save!
			script.permanent_deletion_request_date = nil
			script.save(validate: false)
		end
		flash[:notice] = 'Permanent deletion request rejected.'
		redirect_to script
	end

	def mark
		@script = Script.find(params[:script_id])
		@bots = 'noindex'
	end

	def do_mark
		@script = Script.find(params[:script_id])
		@bots = 'noindex'

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
				render text: "Can't do that!", status: 406
				return
		end

		ma.save! if !ma.action.nil?

		@script.save!
		flash[:notice] = 'Script updated.'
		redirect_to @script
	end

	def stats
		@script, @script_version = versionned_script(params[:script_id], params[:version])

		return if handle_wrong_site(@script)
		return if redirect_to_slug(@script, :script_id)

		install_values = Hash[Script.connection.select_rows("SELECT install_date, installs FROM install_counts where script_id = #{@script.id}")]
		daily_install_values = Hash[Script.connection.select_rows("SELECT DATE(install_date) d, COUNT(*) FROM daily_install_counts where script_id = #{@script.id} GROUP BY d")]
		update_check_values = Hash[Script.connection.select_rows("SELECT update_check_date, update_checks FROM update_check_counts where script_id = #{@script.id}")]
		daily_update_check_values = Hash[Script.connection.select_rows("SELECT DATE(update_check_date) d, COUNT(*) FROM daily_update_check_counts where script_id = #{@script.id} GROUP BY d")]
		@stats = {}
		update_check_start_date = Date.parse('2014-10-23')
		(@script.created_at.to_date..Time.now.utc.to_date).each do |d|
			stat = {}
			stat[:installs] = install_values[d] || daily_install_values[d] || 0
			# this stat not available before that date
			stat[:update_checks] = d >= update_check_start_date ? (update_check_values[d] || daily_update_check_values[d] || 0) : nil
			@stats[d] = stat
		end
		respond_to do |format|
			format.html {
				@canonical_params = [:script_id, :version]
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
		@script = Script.find(params[:script_id])
		@bots = 'noindex'
		return if redirect_to_slug(@script, :script_id)

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

		# only duplications containing listable scripts by others
		@code_duplications = @script.cpd_duplications.includes(:cpd_duplication_scripts => {:script => :user}).select {|dup| dup.cpd_duplication_scripts.any?{|cpdds| cpdds.script.user_id != @script.user_id && cpdds.script.listable?}}.uniq

		@canonical_params = [:script_id]
	end

	def self.get_top_by_sites(script_subset)
		return cache_with_log("scripts/get_top_by_sites/#{script_subset}") do
			get_by_sites(script_subset).sort{|a,b| b[1][:installs] <=> a[1][:installs]}.first(10)
		end
	end

	def self.apply_filters(scripts, params, script_subset)
		if !params[:site].nil?
			if params[:site] == '*'
				scripts = scripts.for_all_sites
			else
				scripts = scripts.joins(:script_applies_tos).where(['text = ?', params[:site]])
			end
		end
		if !params[:set].nil?
			set = ScriptSet.find(params[:set])
			set_script_ids = cache_with_log([set, script_subset]) do
				set.scripts(script_subset).map{|s| s.id}
			end
			scripts = scripts.where(:id => set_script_ids)
		end
		scripts = scripts.order(get_sort(params, false, set))
		return scripts
	end

	def sync_additional_info_form
		render :partial => 'sync_additional_info', :locals => {:la => LocalizedScriptAttribute.new({:attribute_default => false}), :index => params[:index].to_i}
	end

private

	def self.get_sort(params, for_sphinx = false, set = nil)
		# sphinx has these defined as attributes, outside of sphinx they're possibly ambiguous column names
		column_prefix = for_sphinx ? '' : 'scripts.'
		sort = params[:sort] || (!set.nil? ? set.default_sort : nil)
		case sort
			when 'total_installs'
				return "#{column_prefix}total_installs DESC, #{column_prefix}id"
			when 'created'
				return "#{column_prefix}created_at DESC, #{column_prefix}id"
			when 'updated'
				return "#{column_prefix}code_updated_at DESC, #{column_prefix}id"
			when 'daily_installs'
				return "#{column_prefix}daily_installs DESC, #{column_prefix}id"
			when 'ratings'
				return "#{column_prefix}fan_score DESC, #{column_prefix}id"
			when 'name'
				return "#{column_prefix}default_name ASC, #{column_prefix}id"
			else
				params[:sort] = nil
				if for_sphinx
					return "myweight DESC, #{column_prefix}daily_installs DESC, #{column_prefix}id"
				end
				return "#{column_prefix}daily_installs DESC, #{column_prefix}id"
		end
	end

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

	def self.get_code_ids
		newest_sv_ids = Script.connection.select_values('SELECT MAX(id) FROM script_versions GROUP BY script_id')
		script_to_code_ids = Script.connection.select_rows("SELECT script_id, script_code_id FROM script_versions WHERE ID IN (#{newest_sv_ids.join(',')})")
		return Hash[*script_to_code_ids.flatten]
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
		script_id = p[:script_id].to_i.to_s
		return [ip, script_id]
	end

	def self.record_update_check(r, p)
		ip, script_id = per_user_stat_params(r, p)
		return if ip.nil? || script_id.nil?
		Script.record_update_check(script_id, ip)
	end

	def get_listing_link_alternatives
		[
			{:url => url_for(params.merge({:only_path => true, :page => nil, :sort => 'created', :format => :atom})), :type => 'application/atom+xml', :title => t('scripts.listing_created_feed')},
			{:url => url_for(params.merge({:only_path => true, :page => nil, :sort => 'updated', :format => :atom})), :type => 'application/atom+xml', :title => t('scripts.listing_updated_feed')},
			{:url => url_for(params.merge({:only_path => true, :format => :json})), :type => 'application/json'},
			{:url => url_for(params.merge({:only_path => true, :format => :jsonp, :callback => 'callback'})), :type => 'application/javascript'},
			{:url => url_for(params.merge({:only_path => true, :format => :json, :meta => '1'})), :type => 'application/json'},
			{:url => url_for(params.merge({:only_path => true, :format => :jsonp, :meta => '1', :callback => 'callback'})), :type => 'application/javascript'}
		]
	end

	def render_script_list(scripts, options = {})
		@scripts = scripts
		if !(options && options[:skip_filters])
			@scripts = @scripts.paginate(page: params[:page], per_page: get_per_page)
			@scripts = self.class.apply_filters(@scripts, params, script_subset)
		end

		respond_to do |format|
			format.html {
				@feeds = {t('scripts.listing_created_feed') => {sort: 'created'}, t('scripts.listing_updated_feed') => {sort: 'updated'}}
				@canonical_params = [:q, :page, :per_page, :sort]
				@link_alternates = get_listing_link_alternatives
				render :index
			}
			format.atom {
				render :index
			}
			format.json {
				render json: params[:meta] == '1' ? {count: @scripts.count} : @scripts.as_json(include: :user)
			}
			format.jsonp {
				render json: params[:meta] == '1' ? {count: @scripts.count} : @scripts.as_json(include: :user), callback: clean_json_callback_param
			}
		end
	end

	def render_meta_js(script, script_version)
		cached_meta_js = cache_with_log("scripts/meta_js/#{script.cache_key}/#{script_version.id}") do
			script.script_delete_type_id == 2 ? script_version.get_blanked_code : script_version.get_rewritten_meta_block
		end
		render text: cached_meta_js, content_type: 'text/x-userscript-meta'
		ScriptsController.record_update_check(request, params)
	end

	def handle_replaced_script(script)
		if !script.replaced_by_script_id.nil? && script.script_delete_type_id == 1
			redirect_to(script_id: script.replaced_by_script_id, status: 301)
			return true
		end
		return false
	end
end
