require 'coderay'
require 'script_importer/script_syncer'

class ScriptsController < ApplicationController
	# we'll selectively activate the scripts layout when appropriate
	layout 'application'

	before_filter :authorize_by_script_id, :only => [:sync, :sync_update]

	def index
		@scripts = Script.listable.includes(:user).order(get_sort).paginate(:page => params[:page], :per_page => get_per_page)
		if !params[:site].nil?
			@scripts = @scripts.joins(:script_applies_tos).where(['display_text = ?', params[:site]])
		end
		@by_sites = get_by_sites
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
			@scripts = Script.search params[:q], :match_mode => :extended, :page => params[:page],:per_page => get_per_page, :order => get_sort(true), :populate => true
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

	def show
		@script, @script_version = versionned_script(params[:id], params[:version])
		if @script.nil?
			# no good
			render :status => 404
			return
		end
		render :layout => 'scripts'
	end

	def libraries
		@scripts = Script.libraries
	end

	def under_assessment
		@scripts = Script.under_assessment
	end

	def reported
		@scripts = Script.reported
	end

	def show_code
		@script, @script_version = versionned_script(params[:script_id], params[:version])
		if @script.nil?
			# no good
			render :status => 404
			return
		end
		@code = @script_version.code
		render :layout => 'scripts'
	end

	def feedback
		@script, @script_version = versionned_script(params[:script_id], params[:version])
		if @script.nil?
			# no good
			render :status => 404
			return
		end
		render :layout => 'scripts'
	end

	def user_js
		script, script_version = versionned_script(params[:script_id], params[:version])
		respond_to do |format|
			format.any(:html, :all, :js) {
				render :text => script_version.rewritten_code, :content_type => 'text/javascript'
			}
			format.user_script_meta { 
				render :text => script_version.get_rewritten_meta_block, :content_type => 'text/x-userscript-meta'
			}
		end
	end

	def meta_js
		script, script_version = versionned_script(params[:script_id], params[:version])
		render :text => script_version.get_rewritten_meta_block, :content_type => 'text/javascript'
	end

	def install_ping
		Script.record_install(params[:script_id], request.remote_ip)
		render :nothing => true, :status => 204
	end

	def diff
		@script = Script.find(params[:script_id])
		versions = [params[:v1].to_i, params[:v2].to_i]
		@old_version = ScriptVersion.find(versions.min)
		@new_version = ScriptVersion.find(versions.max)
		if @old_version.nil? or @new_version.nil? or @old_version.script_id != @script.id or @new_version.script_id != @script.id
			render :text => 'Invalid versions provided.', :status => 400, :layout => 'scripts'
			return
		end
		@diff = Diffy::Diff.new(@old_version.code, @new_version.code).to_s(:html).html_safe
		render :layout => 'scripts'
	end

	def sync
		@script = Script.find(params[:script_id])
		render :layout => 'scripts'
	end

	def sync_update
		script = Script.find(params[:script_id])

		if !params['stop-syncing'].nil?
			script.script_sync_type_id = nil
			script.script_sync_source_id = nil
			script.last_attempted_sync_date = nil
			script.last_successful_sync_date = nil
			script.sync_identifier = nil
			script.sync_error = nil
			script.save(:validate => false)
			flash[:notice] = 'Script sync turned off.'
			redirect_to script
			return
		end

		script.assign_attributes(params.require(:script).permit(:script_sync_type_id, :sync_identifier))
		if script.script_sync_source_id.nil?
			script.script_sync_source_id = ScriptImporter::ScriptSyncer.get_sync_source_id_for_url(params[:sync_identifier])
		end
		script.save!
		if !params['update-and-sync'].nil?
			case ScriptImporter::ScriptSyncer.sync(script)
				when :success
					flash[:notice] = 'Script successfully synced.'
				when :unchanged
					flash[:notice] = 'Script successfully synced, but no changes found.'
				when :failure
					flash[:notice] = "Script sync failed - #{script.sync_error}."
			end
		end
		redirect_to script
	end

private

	def get_by_sites
		# regexps are eliminated because they're not useful to look at and the link doesn't work anyway (due to
		# the leading slash?)
		return ScriptAppliesTo.joins(:script).select('display_text, count(*) script_count').group('display_text').order('script_count DESC, display_text').where('display_text NOT LIKE "/%" and script_type_id = 1')
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
