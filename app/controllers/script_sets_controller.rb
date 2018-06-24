class ScriptSetsController < ApplicationController

	before_action :authenticate_user!
	before_action :authorize_by_user_id
	before_action :ensure_set_ownership, :except => [:new, :create, :add_to_set]

	def new
		@user = User.find(params[:user_id])
		@set = ScriptSet.new
		@set.user = @user
		@set.favorite = !params[:fav].nil?
		@set.add_child(Script.find(params[:script_id]), false) if !params[:script_id].nil?
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
		if params[:favorite] == '1'
			# check to make sure the user doesn't already have a favorite set
			if !@set.user.favorite_script_set.nil?
				render :action => :new
				return
			end
			make_favorite_set(@set)
		end
		return if handle_update(@set)
		render :action => :new
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

	def destroy
		set = ScriptSet.find(params[:id])
		ScriptSetSetInclusion.where(child_id: set.id).destroy_all
		set.destroy
		redirect_to set.user
	end

	def add_to_set
		action, set_id = params['action-set'].split('-')
		set = nil

		if set_id == 'fav'
			set = current_user.favorite_script_set
			if set.nil?
				set = ScriptSet.new
				set.user = current_user
				make_favorite_set(set)
			end
		elsif set_id == 'new'
			redirect_to new_user_script_set_path(current_user, :script_id => params[:script_id])
			return
		else
			set = ScriptSet.find(set_id)
			if set.user_id != current_user.id
				render_access_denied
				return
			end
		end

		script = Script.find(params[:script_id])

		r = false
		case action
			when 'ai'
				r = set.add_child(script, false)
			when 'ae'
				r = set.add_child(script, true)
			when 'ri'
				r = set.remove_child(script)
			when 're'
				r = set.remove_child(script)
		end

		if r
			if !set.save
				flash[:notice] = 'Could not save set'
			end
		else
			flash[:notice] = 'Could not add to set.'
		end

		redirect_to clean_redirect_param(:return_to) || script
	end

private

	def handle_update(set)
		set.assign_attributes(script_set_params) unless set.favorite

		@child_set_user = nil
		if !params['child-set-user-id'].nil?
			@child_set_user = User.find(params['child-set-user-id'])
		end
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
				ssasi = ScriptSetAutomaticSetInclusion.from_param_value(set_id, false)
				set.add_automatic_child(ssasi)
			end
		end
		if !params['automatic-sets-excluded'].nil?
			params['automatic-sets-excluded'].each do |set_id|
				next if params['remove-selected-automatic-sets'] == 'e' and !params['remove-automatic-sets-excluded'].nil? and params['remove-automatic-sets-excluded'].include?(set_id)
				ssasi = ScriptSetAutomaticSetInclusion.from_param_value(set_id, true)
				set.add_automatic_child(ssasi)
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
					errors << I18n.t('script_sets.could_not_parse_script', value: possible_script)
				else
					script = Script.find(script_id)
					errors << I18n.t('script_sets.already_included', name: script.name(I18n.locale)) if !set.add_child(script, params['script-action'] == 'e')
				end
			end
		end

		# Add set
		if !params['set-action'].nil? and !params['add-child-set'].nil?
			child_set = ScriptSet.find(params['add-child-set'])
			errors << I18n.t('script_sets.already_included', name: child_set.name) if !set.add_child(child_set, params['set-action'] == 'e')
		end

		# Add automatic set
		if !params['add-automatic-script-set-1'].nil?
			ssasi = ScriptSetAutomaticSetInclusion.from_param_value("1-", false)
			errors << I18n.t('script_sets.already_included', name: I18n.t(*ssasi.i18n_params)) if !set.add_automatic_child(ssasi)
		elsif !params['add-automatic-script-set-2'].nil?
			ssasi = ScriptSetAutomaticSetInclusion.from_param_value("2-#{params['add-automatic-script-set-value-2']}", params['add-automatic-script-set-2'] == 'e')
			errors << I18n.t('script_sets.already_included', name: I18n.t(*ssasi.i18n_params)) if !set.add_automatic_child(ssasi)
		elsif !params['add-automatic-script-set-3'].nil? and !params['add-automatic-script-set-value-3'].nil?  and !params['add-automatic-script-set-value-3'].empty?
			automatic_script_set_user = parse_user(params['add-automatic-script-set-value-3'])
			automatic_script_set_user = automatic_script_set_user.nil? ? nil : automatic_script_set_user.id
			ssasi = ScriptSetAutomaticSetInclusion.from_param_value("3-#{automatic_script_set_user}", params['add-automatic-script-set-3'] == 'e')
			errors << I18n.t('script_sets.already_included', name: I18n.t(*ssasi.i18n_params)) if !set.add_automatic_child(ssasi)
		elsif !params['add-automatic-script-set-4'].nil?
			params['add-automatic-script-set-value-4'].each do |l|
				ssasi = ScriptSetAutomaticSetInclusion.from_param_value("4-#{l}", params['add-automatic-script-set-4'] == 'e')
				errors << I18n.t('script_sets.already_included', name: I18n.t(*ssasi.i18n_params)) if !set.add_automatic_child(ssasi)
			end
		end

		# Change the user for whom we're listing the sets
		if !params['child-set-user-refresh'].nil? and !@child_set_user.nil?
			@child_set_user = parse_user(params['child-set-user'])

			if @child_set_user.nil?
				@child_set_user = user
				errors << "Could not parse user '#{CGI::escapeHTML(params['child-set-user'])}'"
			end
		end

		set.valid? if params[:save] == '1'

		errors.each do |err|
			set.errors.add(:base, err)
		end

		# Require recaptcha for creating non-favourite new sets
		if set.errors.empty? && params[:save] == '1' && (!set.new_record? || set.favorite || verify_recaptcha)
			set.save
			redirect_to set.user
			flash[:notice] = I18n.t("script_sets.saved")
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
		params.require(:script_set).permit(:name, :description, :default_sort)
	end

	def make_favorite_set(set)
		set.favorite = true
		# these are not displayed - they are just placeholders
		set.name = 'Favorite'
		set.description = 'Favorite scripts'
	end

	def ensure_set_ownership
		set = ScriptSet.find(params[:id])
		user = User.find(params[:user_id])
		render_404('Script set does not exist') if set.user != user
	end
end
