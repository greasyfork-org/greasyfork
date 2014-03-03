class ScriptsController < ApplicationController
	# we'll selectively activate the scripts layout when appropriate
	layout 'application'

	def index
		case params[:sort]
			when 'total_installs'
				sort = 'total_installs DESC, scripts.id'
			when 'created'
				sort = 'scripts.created_at DESC, scripts.id'
			when 'updated'
				sort = 'scripts.updated_at DESC, scripts.id'
			else
				params[:sort] = nil
				sort = 'daily_installs DESC'
		end

		per_page = 50
		per_page = [params[:per_page].to_i, 200].min if !params[:per_page].nil? and params[:per_page].to_i > 0

		@scripts = Script.active.includes(:user).order(sort).paginate(:page => params[:page], :per_page => per_page)
		if !params[:site].nil?
			@scripts = @scripts.joins(:script_applies_tos).where(['display_text = ?', params[:site]])
		end
		@by_sites = get_by_sites
	end

	def by_site
		@by_sites = get_by_sites
	end

	def show
		@script = versionned_script(params[:id], params[:version])
		if @script.nil?
			# no good
			render :status => 404
			return
		end
		render :layout => 'scripts'
	end

	def under_assessment
		@scripts = Script.under_assessment
	end

	def show_code
		@script = Script.find(params[:script_id])
		@code = @script.script_versions.last.code
		render :layout => 'scripts'
	end

	def feedback
		@script = Script.find(params[:script_id])
		render :layout => 'scripts'
	end

	def user_js
		script = Script.find(params[:script_id])
		render :text => script.script_versions.last.rewritten_code, :content_type => 'text/javascript'
	end

	def meta_js
		script = Script.find(params[:script_id])
		render :text => script.script_versions.last.get_rewritten_meta_block, :content_type => 'text/javascript'
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

private

	def versionned_script(script_id, version_id)
		return nil if script_id.nil?
		script_id = script_id.to_i
		return Script.find(script_id) if version_id.nil?
		version_id = version_id.to_i
		script_version = ScriptVersion.find(version_id)
		return nil if script_version.nil? or script_version.script_id != script_id
		script = Script.new
		script.apply_from_script_version(script_version)
		script.id = script_id
		script.updated_at = script_version.updated_at
		script.user = script_version.script.user
		script.created_at = script_version.created_at
		script.updated_at = script_version.updated_at
		return script
	end

	def get_by_sites
		# regexps are eliminated because they're not useful to look at and the link doesn't work anyway (due to
		# the leading slash?)
		return ScriptAppliesTo.select('display_text, count(*) script_count').group('display_text').order('script_count DESC, display_text').where('display_text NOT LIKE "/%"')
	end

end
