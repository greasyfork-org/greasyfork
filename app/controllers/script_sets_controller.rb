class ScriptSetsController < ApplicationController

	before_filter :authenticate_user!
	before_filter :authorize_by_user_id

	def new
		@user = User.find(params[:user_id])
		@set = ScriptSet.new
		@set.user = @user
		@child_set_user = @user
	end

	def edit
		@set = ScriptSet.find(params[:id])
		@user = User.find(params[:user_id])
		@child_set_user = @user
	end

	def create
		@set = ScriptSet.new
		@set.user = User.find(params[:user_id])
		return if handle_update(@set)
		render :action => :edit
	end

	def update
		@set = ScriptSet.find(params[:id])

		# blow away everything, the form will resubmit the info
		@set.set_inclusions.each{|si| si.mark_for_destruction}
		@set.automatic_set_inclusions.each{|si| si.mark_for_destruction}
		@set.script_inclusions.each{|si| si.mark_for_destruction}

		return if handle_update(@set)
		render :action => :edit
	end

private

	def handle_update(set)
		set.assign_attributes(script_set_params)

		@child_set_user = User.find(params['child-set-user-id'])
		errors = []

		# Previously added scripts
		if !params['scripts-included'].nil?
			params['scripts-included'].each do |script_id|
				next if params['remove-selected-scripts'] == 'i' and !params['remove-scripts-included'].nil? and params['remove-scripts-included'].include?(script_id)
				set.add_child(Script.find(script_id), false)
			end
		end
		if !params['scripts-excluded'].nil?
			params['scripts-excluded'].each do |script_id|
				next if params['remove-selected-scripts'] == 'e' and !params['remove-scripts-excluded'].nil? and params['remove-scripts-excluded'].include?(script_id)
				set.add_child(Script.find(script_id), true)
			end
		end

		# Previously added sets
		if !params['sets-included'].nil?
			params['sets-included'].each do |set_id|
				next if params['remove-selected-sets'] == 'i' and !params['remove-sets-included'].nil? and params['remove-sets-included'].include?(set_id)
				set.add_child(ScriptSet.find(set_id), false)
			end
		end
		if !params['sets-excluded'].nil?
			params['sets-excluded'].each do |set_id|
				next if params['remove-selected-sets'] == 'e' and !params['remove-sets-excluded'].nil? and params['remove-sets-excluded'].include?(set_id)
				set.add_child(ScriptSet.find(set_id), true)
			end
		end

		# Previously added automatic sets
		if !params['automatic-sets-included'].nil?
			params['automatic-sets-included'].each do |set_id|
				next if params['remove-selected-automatic-sets'] == 'i' and !params['remove-automatic-sets-included'].nil? and params['remove-automatic-sets-included'].include?(set_id)
				set.add_child(set_id, false)
			end
		end
		if !params['automatic-sets-excluded'].nil?
			params['automatic-sets-excluded'].each do |set_id|
				next if params['remove-selected-automatic-sets'] == 'e' and !params['remove-automatic-sets-excluded'].nil? and params['remove-automatic-sets-excluded'].include?(set_id)
				set.add_child(set_id, true)
			end
		end

		# Add script
		if !params['script-action'].nil? and !params['add-script'].nil?
			params['add-script'].split(/\s+/).each do |possible_script|
				script_id = nil
				# is it an ID?
				begin
					script_id = Integer(possible_script)
				rescue ArgumentError, TypeError
				end

				#is it a URL?
				if script_id.nil?
					begin
						path_params = Rails.application.routes.recognize_path(possible_script)
						script_id = path_params[:id]
					rescue ActionController::RoutingError
					end
				end

				if script_id.nil?
					errors << "Could not parse script '#{CGI::escapeHTML(possible_script)}'"
				else
					set.add_child(Script.find(script_id), params['script-action'] == 'e')
				end
			end
		end

		# Add set
		if !params['set-action'].nil? and !params['add-child-set'].nil?
			set.add_child(ScriptSet.find(params['add-child-set']), params['set-action'] == 'e')
		end

		# Add automatic set
		if !params['add-automatic-script-set-1'].nil?
			set.add_child("1-", false)
		elsif !params['add-automatic-script-set-2'].nil?
			set.add_child("2-#{params['add-automatic-script-set-value-2']}", params['add-automatic-script-set-2'] == 'e')
		elsif !params['add-automatic-script-set-3'].nil? and !params['add-automatic-script-set-value-3'].nil?  and !params['add-automatic-script-set-value-3'].empty?
			automatic_script_set_user = parse_user(params['add-automatic-script-set-value-3'])
			automatic_script_set_user = automatic_script_set_user.nil? ? nil : automatic_script_set_user.id
			set.add_child("3-#{automatic_script_set_user}", params['add-automatic-script-set-3'] == 'e')
		elsif !params['add-automatic-script-set-4'].nil?
			params['add-automatic-script-set-value-4'].each do |l|
				set.add_child("4-#{l}", params['add-automatic-script-set-4'] == 'e')
			end
		end

		# Change the user for whom we're listing the sets
		if !params['child-set-user-refresh'].nil?
			@child_set_user = parse_user(params['child-set-user'])

			if @child_set_user.nil?
				@child_set_user = user
				errors << "Could not parse user '#{CGI::escapeHTML(params['child-set-user'])}'"
			end
		end

		set.valid?
		errors.each do |err|
			set.errors.add(:base, err)
		end

		if set.errors.empty? and params[:save] == '1'
			set.save
			redirect_to set.user
			return true
		end

		return false
	end

	def parse_user(v)
		# is it an ID?
		begin
			return User.find(Integer(v))
		rescue ArgumentError, TypeError
		end

		#is it a URL?
		begin
			path_params = Rails.application.routes.recognize_path(v)
			return User.find(path_params[:id]) if path_params.has_key?(:id)
		rescue ActionController::RoutingError
		end

		#is it a name?
		return User.find_by_name(v)
	end

	def script_set_params
		params.require(:script_set).permit(:name, :description)
	end

end
