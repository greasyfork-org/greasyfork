class SessionsController < Devise::SessionsController

	skip_before_action :verify_authenticity_token, :only => [:omniauth_callback]

	def after_sign_in_path_for(resource)
		if resource.is_a?(User) && resource.banned?
			sign_out resource
			flash.delete(:notice) # get rid of "Signed in successfully."
			flash[:alert] = "This account has been banned."
			root_path
		else
			super
		end
	end

	# delete Vanilla cookies too
	def destroy
		cookies.delete 'Vanilla'
		cookies.delete 'Vanilla-Volatile'
		super
	end

	def omniauth_callback

		if !params[:failure].nil?
			handle_omniauth_failure
			return
		end

		if !params[:error].nil?
			handle_omniauth_failure(params[:error])
			return
		end

		return_to = clean_redirect_param(:origin)
		o = request.env['omniauth.auth']
		provider = o[:provider]
		uid = o[:uid]
		email = o[:info][:email]
		email = nil if !email.nil? and email.empty?
		if session[:chosen_name]
			# from name conflict
			name = session[:chosen_name]
			session.delete(:chosen_name)
			# don't go to omniauth.origin (the first sign in attempt), go to *its* omniauth.origin
			request.env['omniauth.origin'] = params[:origin]
		else
		name = o[:info][:nickname] || # GitHub
			(provider == 'browser_id' ? o[:info][:name].split('@').first : nil) || # Persona
			o[:info][:name] # Google
		end
		url = (o[:extra] && o[:extra][:raw_info] && o[:extra][:raw_info][:html_url]) || # GitHub
			(o[:extra] && o[:extra][:raw_info] && o[:extra][:raw_info][:profile]) # Google

		# does the identity already exist?
		identity = Identity.find_by_provider_and_uid(provider, uid)
		if !identity.nil?
			# existing user
			user = identity.user
			if !current_user.nil? and user.id != current_user.id
				# another user has this already!
				flash[:notice] = t('users.external_sign_in_already_used', :provider => Identity.pretty_provider(provider), :user_name => user.name)
				redirect_to return_to || request.env['omniauth.origin'] || after_sign_in_path_for(current_user)
				return
			end
			# update the existing user for syncing accounts
			if identity.syncing and (user.name != name or (user.email != email and !email.nil?))
				user.name = name
				user.email = email unless email.nil?
				# if we can't save (name already used?) that's ok, we just won't sync
				if !user.save
					user.reload
				end
			end
			sign_in user
			set_flash_message(:notice, :signed_in)
			redirect_to return_to || after_sign_in_path_for(user)
			return
		end

		# identity did not previously exist

		# user already logged in - add identity to their account
		if !current_user.nil?
			identity = Identity.new({:provider => provider, :uid => uid, :syncing => false, :url => url})
			if !identity.valid?
				handle_omniauth_failure(identity.errors.full_messages.join(', '))
				return
			end
			current_user.identities << identity
			current_user.save(:validate => false)
			flash[:notice] = t('users.external_sign_in_added', :provider => Identity.pretty_provider(provider))
			redirect_to return_to || request.env['omniauth.origin'] || after_sign_in_path_for(current_user)
			return
		end

		# does another user already have that e-mail?
		if !email.nil?
			@same_email_user = User.find_by_email(email)
			if !@same_email_user.nil?
				@provider = Identity.pretty_provider(provider)
				@email = email
				render 'omniauth_callback_same_email'
				return
			end
		end

		# we need to create a user, but the provider didn't provide an email
		if email.nil?
			@provider = Identity.pretty_provider(provider)
			render 'omniauth_callback_no_email'
			return
		end

		# does another user already have that name?
		same_name_user = User.find_by_name(name)
		if !same_name_user.nil?
			@provider = provider
			@name = name
			render 'omniauth_callback_same_name'
			return
		end

		# create a new user
		user = User.new({:name => name, :email => email, :identities => [Identity.new({:provider => provider, :uid => uid, :syncing => true, :url => url})]})
		if !user.save
			handle_omniauth_failure(user.errors.full_messages.join(', '))
			return
		end
		sign_in user
		redirect_to return_to || after_sign_in_path_for(user)
	end

	def omniauth_failure
		handle_omniauth_failure(params[:message])
	end

	def name_conflict
		session[:chosen_name] = params[:name]
		redirect_to "/auth/#{params[:provider]}"
	end

private

	def handle_omniauth_failure(error = 'unknown')
		flash[:notice] = t('users.external_sign_in_failed', :provider => Identity.pretty_provider(params[:provider] || params[:strategy]), :error => error)
		redirect_to clean_redirect_param(:origin) || request.env['omniauth.origin'] || new_user_session_path
	end

	def clean_redirect_param(param_name)
		v = params[param_name]
		return nil if v.nil?
		return nil if v.include?('failure')
		return URI.parse(v).path
	end

end
