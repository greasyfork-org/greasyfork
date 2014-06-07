require 'coderay'
require 'script_importer/script_syncer'

class ScriptsController < ApplicationController
	layout 'application', :except => [:show, :show_code, :feedback, :diff, :sync, :sync_update, :delete, :undelete]

	before_filter :authorize_by_script_id, :only => [:sync, :sync_update]
	before_filter :authorize_by_script_id_or_moderator, :only => [:delete, :do_delete, :undelete, :do_undelete]
	before_filter :check_for_locked_by_script_id, :only => [:sync, :sync_update, :delete, :do_delete, :undelete, :do_undelete]
	before_filter :check_for_deleted_by_id, :only => [:show]
	before_filter :check_for_deleted_by_script_id, :only => [:show_code, :feedback, :user_js, :meta_js, :install_ping, :diff]

	skip_before_action :verify_authenticity_token, :only => [:install_ping]

	#########################
	# Collections
	#########################

	def index
		@scripts = Script.listable.includes([:user, :script_type]).order(get_sort).paginate(:page => params[:page], :per_page => get_per_page)
		if !params[:site].nil?
			if params[:site] == '*'
				@scripts = @scripts.includes(:script_applies_tos).where('script_applies_tos.id IS NULL')
			else
				@scripts = @scripts.joins(:script_applies_tos).where(['text = ?', params[:site]])
			end
		end
		@by_sites = get_top_by_sites
	end

	def by_site
		@by_sites = get_by_sites
	end

	def search
		if params[:q].nil? or params[:q].empty?
			redirect_to scripts_path
			return
		end
		begin
			@scripts = Script.search params[:q], :match_mode => :extended, :page => params[:page], :per_page => get_per_page, :order => get_sort(true), :populate => true, :includes => :script_type
			# make it run now so we can catch syntax errors
			@scripts.empty?
		rescue ThinkingSphinx::SyntaxError => e
			flash[:alert] = "Invalid search query - '#{params[:q]}'."
			# back to the main listing
			redirect_to scripts_path
			return
		end
		render :action => 'index'
	end

	def libraries
		@scripts = Script.libraries
	end

	def under_assessment
		@no_bots = true
		@scripts = Script.under_assessment
	end

	def reported
		@no_bots = true
		@scripts = Script.reported
	end

	#########################
	# Single resource
	#########################

	def show
		@script, @script_version = versionned_script(params[:id], params[:version])
		return if redirect_to_slug(@script, :id)
		@no_bots = true if !params[:version].nil?
	end

	def show_code
		@script, @script_version = versionned_script(params[:script_id], params[:version])
		return if redirect_to_slug(@script, :script_id)
		@code = @script_version.rewritten_code
		@no_bots = true if !params[:version].nil?
	end

	def feedback
		@script, @script_version = versionned_script(params[:script_id], params[:version])
		return if redirect_to_slug(@script, :script_id)
		@no_bots = true if !params[:version].nil?
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
		@no_bots = true
	end

	def sync
		@script = Script.find(params[:script_id])
		return if redirect_to_slug(@script, :script_id)
		@no_bots = true
	end

	def sync_update
		@script = Script.find(params[:script_id])
		@no_bots = true

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
		@no_bots = true
	end

	def undelete
		@script = Script.find(params[:script_id])
		@no_bots = true
	end

	def do_delete
		script = Script.find(params[:script_id])
		@no_bots = true
		if current_user.moderator? && current_user != script.user
			script.locked = params[:locked].nil? ? false : params[:locked]
			ma = ModeratorAction.new
			ma.moderator = current_user
			ma.script = script
			ma.action = script.locked ? 'Delete and lock' : 'Delete'
			ma.reason = params[:reason]
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
		@no_bots = true
		script = Script.find(params[:script_id])
		if current_user.moderator? && current_user != script.user
			ma = ModeratorAction.new
			ma.moderator = current_user
			ma.script = script
			ma.action = 'Undelete'
			ma.reason = params[:reason]
			ma.save!
			script.locked = false
			if script.user.banned
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
		script.save(:validate => false)
		redirect_to script
	end

private

	def get_by_sites
		sql =<<-EOF
			SELECT
				text, SUM(daily_installs) install_count
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
		return [{'text' => nil, 'install_count' => get_all_sites_count}] + Script.connection.select_all(sql)
	end

	def get_top_by_sites
		sql =<<-EOF
			SELECT
				text, SUM(daily_installs) install_count
			FROM script_applies_tos
			JOIN scripts s ON script_id = s.id
			WHERE
				domain
				AND script_type_id = 1
				AND script_delete_type_id IS NULL
				AND !uses_disallowed_external
			GROUP BY text
			ORDER BY install_count DESC, text
			LIMIT 5
		EOF
		top_sites = Script.connection.select_all(sql).to_a
		# combine with "All sites" number
		top_sites << {'text' => nil, 'install_count' => get_all_sites_count}
		return top_sites.sort{|a,b| b['install_count'] <=> a['install_count']}.first(5)
	end

	def get_all_sites_count
		sql =<<-EOF
			SELECT
				sum(daily_installs) install_count
			FROM scripts
			WHERE
				script_type_id = 1
				AND script_delete_type_id is null
				AND !uses_disallowed_external
				AND NOT EXISTS (SELECT * FROM script_applies_tos WHERE script_id = scripts.id)
		EOF
		return Script.connection.select_value(sql)
	end

	def get_per_page
		per_page = 50
		per_page = [params[:per_page].to_i, 200].min if !params[:per_page].nil? and params[:per_page].to_i > 0
		return per_page
	end

	def get_sort(for_sphinx = false)
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
			else
				params[:sort] = nil
				if for_sphinx
					return ''#"myweight DESC, #{column_prefix}id"
				end
				return "#{column_prefix}daily_installs DESC, #{column_prefix}id"
		end
	end

end
