class ScriptVersionsController < ApplicationController

	before_filter :authenticate_user!, :except => [:index]
	before_filter :authorize_by_script_id, :except => [:index]
	before_filter :check_for_deleted_by_script_id
	before_filter :check_for_locked_by_script_id, :except => [:index]

	layout 'scripts', only: [:index]

	def index
		@script, @script_version = versionned_script(params[:script_id], params[:version])
		@bots = 'noindex' if !params[:show_all_versions].nil?
		return if redirect_to_slug(@script, :script_id)
	end

	def new
		@bots = 'noindex'
		@script_version = ScriptVersion.new
		if !params[:script_id].nil?
			@script = Script.find(params[:script_id]) 
			@script_version.script = @script
			previous_script = @script.script_versions.last
			@script_version.code = previous_script.code
			@script_version.additional_info = previous_script.additional_info
			@script_version.additional_info_markup = previous_script.additional_info_markup
			render :layout => 'scripts'
		else
			@script = Script.new
			@script.script_type_id = 1
			@script_version.script = @script
		end
	end

	def create
		@bots = 'noindex'
		@script_version = ScriptVersion.new
		@script_version.assign_attributes(script_version_params)

		if params[:script_id].nil?
			@script = Script.new
			@script.user = current_user
		else
			@script = Script.find(params[:script_id])
		end

		@script_version.script = @script
		@script.script_type_id = params['script']['script_type_id']
		@script.locale_id = params['script']['locale_id']

		if !params[:code_upload].nil?
			uploaded_content = params[:code_upload].read
			if !uploaded_content.force_encoding("UTF-8").valid_encoding?
				@script_version.errors.add(:code, 'uploaded must be UTF-8 text')
				render :new
				return
			end
			@script_version.code = uploaded_content
		end

		if @script.library?
			# accept name and description as params for libraries, as they may not have meta blocks
			@script.name = params[:name] if !params[:name].nil?
			@script.description = params[:description] if !params[:description].nil?
			# automatically add a version for libraries, if missing
			@script_version.add_missing_version = true if @script.library?
		end

		@script_version.calculate_all(@script.description)
		@script.apply_from_script_version(@script_version)

		if @script.locale_id.nil?
			@script.locale = @script.detect_locale
		end

		# if the script is (being) deleted, don't require a description
		@script.description = 'Deleted' if @script.deleted? and @script.description.nil?

		# support preview for JS disabled users
		if !params[:preview].nil?
			@preview = view_context.format_user_text(@script_version.additional_info, @script_version.additional_info_markup)
		end

		# Don't save if this is a preview or if there's something invalid. For non-previews,
		# ensure all validations are run - short circuit the OR.
		if !params[:preview].nil? or (!@script.valid? | !@script_version.valid?)
			if @script.new_record?
				render :new
			else
				# get the original script for display within the scripts layout
				@script.reload
				# but retain the script type!
				@script.script_type_id = params['script']['script_type_id']
				render :new, :layout => 'scripts'
			end
			return
		end

		@script.script_versions << @script_version
		@script.save!

		flash[:notice] = 'Your script has been posted, but will not be made public until its external scripts fall within Greasy Fork\'s guidelines.' if @script_version.accepted_assessment

		redirect_to @script
	end

private

	def script_version_params
		params.require(:script_version).permit(:code, :changelog, :additional_info, :additional_info_markup, :accepted_assessment, :version_check_override, :add_missing_version, :namespace_check_override, :add_missing_namespace, :minified_confirmation)
	end

end
