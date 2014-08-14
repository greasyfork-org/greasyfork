require 'coderay'
require 'script_importer/script_syncer'

class ScriptsController < ApplicationController
	layout 'application', :except => [:show, :show_code, :feedback, :diff, :sync, :sync_update, :delete, :undelete, :stats, :derivatives]

	before_filter :authorize_by_script_id, :only => [:sync, :sync_update]
	before_filter :authorize_by_script_id_or_moderator, :only => [:delete, :do_delete, :undelete, :do_undelete, :derivatives]
	before_filter :check_for_locked_by_script_id, :only => [:sync, :sync_update, :delete, :do_delete, :undelete, :do_undelete]
	before_filter :check_for_deleted_by_id, :only => [:show]
	before_filter :check_for_deleted_by_script_id, :only => [:show_code, :feedback, :user_js, :meta_js, :install_ping, :diff]
	before_filter :authorize_for_moderators_only, :only => [:minified]

	skip_before_action :verify_authenticity_token, :only => [:install_ping]
	protect_from_forgery :except => [:user_js, :meta_js]

	#########################
	# Collections
	#########################

	def index
		@scripts = Script.listable.includes([:user, :script_type]).paginate(:page => params[:page], :per_page => get_per_page)
		@scripts = self.class.apply_filters(@scripts, params)
		if !params[:set].nil?
			@set = ScriptSet.find(params[:set])
		end
		@by_sites = self.class.get_top_by_sites
		@bots = 'noindex,follow' if !params[:sort].nil?
		@feeds = {t('scripts.listing_created_feed') => {:sort => 'created'}, t('scripts.listing_updated_feed') => {:sort => 'updated'}}

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

		respond_to do |format|
			format.html
			format.atom
		end
	end

	def by_site
		@by_sites = self.class.get_by_sites
	end

	def search
		if params[:q].nil? or params[:q].empty?
			redirect_to scripts_path
			return
		end
		@bots = 'noindex,follow'
		begin
			@scripts = Script.search params[:q], :match_mode => :extended, :page => params[:page], :per_page => get_per_page, :order => self.class.get_sort(params, true), :populate => true, :includes => :script_type
			# make it run now so we can catch syntax errors
			@scripts.empty?
		rescue ThinkingSphinx::SyntaxError => e
			flash[:alert] = "Invalid search query - '#{params[:q]}'."
			# back to the main listing
			redirect_to scripts_path
			return
		end
		@title = t('scripts.listing_title_for_search', :search_string => params[:q])
		@feeds = {t('scripts.listing_created_feed') => {:sort => 'created'}, t('scripts.listing_updated_feed') => {:sort => 'updated'}}
		render :action => 'index'
	end

	def libraries
		@scripts = Script.libraries
	end

	def under_assessment
		@bots = 'noindex'
		@scripts = Script.under_assessment
	end

	def reported
		@bots = 'noindex'
		@scripts = Script.reported
	end

	def minified
		@bots = 'noindex'
		@scripts = []
		Script.order(get_sort).where(:locked => false).each do |script|
			sv = script.get_newest_saved_script_version
			@scripts << script if sv.appears_minified
		end
		@paginate = false
		@title = "Potentially minified user scripts on Greasy Fork"
		render :action => 'index'
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
		@scripts = Script.order(get_sort).where(:locked => false).includes([:user, :script_type, :script_delete_type]).where(:id => script_ids)
		@paginate = false
		@title = t('scripts.listing_title_for_code_search', :search_string => params[:c])
		render :action => 'index'
	end

	#########################
	# Single resource
	#########################

	def show
		@script, @script_version = versionned_script(params[:id], params[:version])
		return if redirect_to_slug(@script, :id)
		if !params[:version].nil?
			@bots = 'noindex'
		elsif @script.unlisted?
			@bots = 'noindex,follow'
		end
		@by_sites = self.class.get_by_sites
	end

	def show_code
		@script, @script_version = versionned_script(params[:script_id], params[:version])

		# some weird safari client tries to do this
		if params[:format] == 'meta.js'
			redirect_to script_meta_js_path(params.merge({:name => @script.name, :format => nil}))
			return
		end

		return if redirect_to_slug(@script, :script_id)
		@code = @script_version.rewritten_code
		@bots = 'noindex' if !params[:version].nil?
	end

	def feedback
		@script, @script_version = versionned_script(params[:script_id], params[:version])
		return if redirect_to_slug(@script, :script_id)
		@bots = 'noindex' if !params[:version].nil?
	end

	def user_js
		script, script_version = versionned_script(params[:script_id], params[:version])
		respond_to do |format|
			format.any(:html, :all, :js) {
				render :text => script.script_delete_type_id == 2 ? script_version.get_blanked_code : script_version.rewritten_code, :content_type => 'text/javascript'
			}
			format.user_script_meta { 
				render :text => script.script_delete_type_id == 2 ? script_version.get_blanked_code : script_version.get_rewritten_meta_block, :content_type => 'text/x-userscript-meta'
			}
		end
	end

	def meta_js
		script, script_version = versionned_script(params[:script_id], params[:version])
		render :text => script.script_delete_type_id == 2 ? script_version.get_blanked_code : script_version.get_rewritten_meta_block, :content_type => 'text/x-userscript-meta'
	end

	def install_ping
		# verify for CSRF, but do it in a way that avoids an exception. Prevents monitoring from going nuts.
		if !verified_request?
			render :nothing => true, :status => 422
			return
		end
		# strip the slug
		Script.record_install(params[:script_id].to_i.to_s, request.remote_ip)
		render :nothing => true, :status => 204
	end

	def diff
		@script = Script.find(params[:script_id])
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
		@diff = Diffy::Diff.new(@old_version.code, @new_version.code, :context => @context, :include_plus_and_minus_in_html => true, :include_diff_info => true).to_s(:html).html_safe
		@bots = 'noindex'
	end

	def sync
		@script = Script.find(params[:script_id])
		return if redirect_to_slug(@script, :script_id)
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
			@script.save(:validate => false)
			flash[:notice] = 'Script sync turned off.'
			redirect_to @script
			return
		end

		@script.assign_attributes(params.require(:script).permit(:script_sync_type_id, :sync_identifier))
		if @script.script_sync_source_id.nil?
			@script.script_sync_source_id = ScriptImporter::ScriptSyncer.get_sync_source_id_for_url(params[:sync_identifier])
		end
		if !@script.save
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
		@other_scripts = Script.where(:user => @script.user).where(:locked => false).where(['id != ?', @script.id]).count
		@bots = 'noindex'
	end

	def undelete
		@script = Script.find(params[:script_id])
		@bots = 'noindex'
	end

	def do_delete
		script = Script.find(params[:script_id])
		@bots = 'noindex'
		if current_user.moderator? && current_user != script.user
			script.locked = params[:locked].nil? ? false : params[:locked]
			ma = ModeratorAction.new
			ma.moderator = current_user
			ma.script = script
			ma.action = script.locked ? 'Delete and lock' : 'Delete'
			ma.reason = params[:reason]
			script.delete_reason = params[:reason]
			ma.save!
			if params[:banned]
				ma_ban = ModeratorAction.new
				ma_ban.moderator = current_user
				ma_ban.user = script.user
				ma_ban.action = 'Ban'
				ma_ban.reason = params[:reason]
				ma_ban.save!
				script.user.banned = true
				script.user.save!
			end
		end
		script.script_delete_type_id = params[:script_delete_type_id]
		script.save(:validate => false)
		redirect_to script
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
		script.delete_reason = nil
		script.save(:validate => false)
		redirect_to script
	end

	def stats
		@script, @script_version = versionned_script(params[:script_id], params[:version])
		install_values = Hash[Script.connection.select_rows("SELECT install_date, installs FROM install_counts where script_id = #{@script.id}")]
		daily_install_values = Hash[Script.connection.select_rows("SELECT DATE(install_date) d, COUNT(*) FROM daily_install_counts where script_id = #{@script.id} GROUP BY d")]
		@install_data = {}
		(@script.created_at.to_date..Time.now.utc.to_date).each do |d|
			v = install_values[d]
			if v.nil?
				v2 = daily_install_values[d]
				@install_data[d] = v2.nil? ? 0 : v2
			else
				@install_data[d] = v
			end
		end
	end

	def derivatives
		@script = Script.find(params[:script_id])
		@bots = 'noindex'
		return if redirect_to_slug(@script, :script_id)

		similar_names = {}
		Script.listable.where(['user_id != ?', @script.user_id]).select([:id, :name]).each do |other_script|
			similar_names[other_script.id] = Levenshtein.normalized_distance(@script.name, other_script.name)
		end
		similar_names = similar_names.sort_by{|k, v| v}.take(10)
		@similar_name_scripts = similar_names.map{|a| Script.includes([:user, :license]).find(a[0])}

		@same_namespaces = []
		@same_namespaces = Script.listable.where(['user_id != ?', @script.user_id]).where(:namespace => @script.namespace).includes([:user, :license]) if !@script.namespace.nil?

		# only duplications containing listable scripts by others
		@code_duplications = @script.cpd_duplications.includes(:cpd_duplication_scripts => {:script => :user}).select {|dup| dup.cpd_duplication_scripts.any?{|cpdds| cpdds.script.user_id != @script.user_id && cpdds.script.listable?}}
	end

	def self.get_top_by_sites
		return Rails.cache.fetch("scripts/get_top_by_sites") do
			get_by_sites.sort{|a,b| b[1][:installs] <=> a[1][:installs]}.first(10)
		end
	end

	def self.apply_filters(scripts, params)
		scripts = scripts.order(get_sort(params))
		if !params[:site].nil?
			if params[:site] == '*'
				scripts = scripts.for_all_sites
			else
				scripts = scripts.joins(:script_applies_tos).where(['text = ?', params[:site]])
			end
		end
		if !params[:set].nil?
			set = ScriptSet.find(params[:set])
			set_script_ids = Rails.cache.fetch(set) do
				set.scripts.map{|s| s.id}
			end
			scripts = scripts.where(:id => set_script_ids)
		end
		return scripts
	end

private

	def self.get_sort(params, for_sphinx = false)
		# sphinx has these defined as attributes, outside of sphinx they're possibly ambiguous column names
		column_prefix = for_sphinx ? '' : 'scripts.'
		case params[:sort]
			when 'total_installs'
				return "#{column_prefix}total_installs DESC, #{column_prefix}id"
			when 'created'
				return "#{column_prefix}created_at DESC, #{column_prefix}id"
			when 'updated'
				return "#{column_prefix}code_updated_at DESC, #{column_prefix}id"
			when 'daily_installs'
				return "#{column_prefix}daily_installs DESC, #{column_prefix}id"
			when 'fans'
				return "#{column_prefix}fan_score DESC, #{column_prefix}id"
			when 'name'
				return "#{column_prefix}name ASC, #{column_prefix}id"
			else
				params[:sort] = nil
				if for_sphinx
					return ''#"myweight DESC, #{column_prefix}id"
				end
				return "#{column_prefix}daily_installs DESC, #{column_prefix}id"
		end
	end

	# Returns a hash, key: site name, value: hash with keys installs, scripts
	def self.get_by_sites
		return Rails.cache.fetch("scripts/get_by_sites") do
			sql =<<-EOF
				SELECT
					text, SUM(daily_installs) install_count, COUNT(DISTINCT s.id) script_count
				FROM script_applies_tos
				JOIN scripts s ON script_id = s.id
				WHERE
					domain
					AND script_type_id = 1
					AND script_delete_type_id IS NULL
					AND !uses_disallowed_external
				GROUP BY text
				ORDER BY text
			EOF
			# combine with "All sites" number
			a = ([[nil] + get_all_sites_count.values.to_a] + Script.connection.select_rows(sql))
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
				AND !uses_disallowed_external
				AND NOT EXISTS (SELECT * FROM script_applies_tos WHERE script_id = scripts.id)
		EOF
		return Script.connection.select_all(sql).first
	end

	def get_per_page
		per_page = 50
		per_page = [params[:per_page].to_i, 200].min if !params[:per_page].nil? and params[:per_page].to_i > 0
		return per_page
	end

	def self.get_code_ids
		newest_sv_ids = Script.connection.select_values('SELECT MAX(id) FROM script_versions GROUP BY script_id')
		script_to_code_ids = Script.connection.select_rows("SELECT script_id, script_code_id FROM script_versions WHERE ID IN (#{newest_sv_ids.join(',')})")
		return Hash[*script_to_code_ids.flatten]
	end

end
