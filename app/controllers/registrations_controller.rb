# per https://github.com/plataformatec/devise/wiki/How-To:-Customize-the-redirect-after-a-user-edits-their-profile
class RegistrationsController < Devise::RegistrationsController
  include LoginMethods
  include BrowserCaching
  include UserTextHelper

  before_action :check_captcha, only: [:create]
  before_action :check_read_only_mode
  before_action :check_ip_and_params_email, only: :create
  before_action :disable_browser_caching!

  # https://github.com/plataformatec/devise/wiki/How-To%3a-Allow-users-to-edit-their-account-without-providing-a-password
  def update
    @user = User.find(current_user.id)

    successfully_updated = if needs_password?(@user, params)
                             @user.update_with_password(devise_parameter_sanitizer.sanitize(:account_update))
                           else
                             # remove the virtual current_password attribute
                             # update_without_password doesn't know how to ignore it
                             params[:user].delete(:current_password)
                             @user.update_without_password(devise_parameter_sanitizer.sanitize(:account_update))
                           end

    if successfully_updated
      @user.construct_mentions(detect_possible_mentions(@user.profile, @user.profile_markup))
      @user.save!

      # Sign in the user bypassing validation in case their password changed
      bypass_sign_in(@user)
      # Show the message in their new locale
      set_flash_message :notice, :updated, { locale: @user.available_locale_code }
      redirect_to after_update_path_for(@user)
    else
      render 'edit'
    end
  end

  protected

  def after_update_path_for(resource)
    # Use the user's locale after update
    stored_location_for(resource) || user_path(resource, (resource.available_locale_code.nil? ? {} : { locale: resource.available_locale_code }))
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || user_path(resource)
  end

  def check_captcha
    return if verify_recaptcha

    self.resource = resource_class.new sign_up_params
    resource.validate # Look for any other validation errors besides Recaptcha
    set_minimum_password_length
    respond_with_navigational(resource) { render :new }
  end

  def check_ip_and_params_email
    email = params.dig('user', 'email')
    return unless email

    email_domain = email.split('@').last
    return unless email_domain

    return unless Rails.application.config.ip_address_tracking

    if User.where(banned_at: 1.week.ago..)
           .where(current_sign_in_ip: request.remote_ip)
           .where(email_domain: email_domain)
           .count >= 2
      @text = 'Your IP address has been banned.'
      render 'home/error', layout: 'application'
    end
  end

  private

  def needs_password?(_user, _params)
    false
  end
end
