class ScriptVersionsController < ApplicationController

	before_filter :authenticate_user!, :except => [:index]
	before_filter :authorize_by_script_id, :except => [:index]
	before_filter :check_for_deleted_by_script_id
	before_filter :check_for_locked_by_script_id, :except => [:index]

	layout 'scripts', only: [:index]

	def index
		@script, @script_version = versionned_script(params[:script_id], params[:version])
		return if redirect_to_slug(@script, :script_id)
	end

	def new
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

		if !params[:code_upload].nil?
			uploaded_content = params[:code_upload].read
			if !uploaded_content.force_encoding("UTF-8").valid_encoding?
				@script_version.errors.add(:code, 'uploaded must be UTF-8 text')
				render :new
				return
			end
			@script_version.code = uploaded_content
		end

		@script_version.calculate_all
		@script.apply_from_script_version(@script_version)

		# if the script is (being) deleted, don't require a description
		@script.description = 'Deleted' if @script.deleted? and @script.description.nil?

		# ensure all validations are run - short circuit the OR
		if !@script.valid? | !@script_version.valid?
			if @script.new_record?
				render :new
			else
				# get the original script for display within the scripts layout
				@script.reload
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
		params.require(:script_version).permit(:code, :changelog, :additional_info, :additional_info_markup, :accepted_assessment, :version_check_override, :add_missing_version, :namespace_check_override, :add_missing_namespace)
	end

end
