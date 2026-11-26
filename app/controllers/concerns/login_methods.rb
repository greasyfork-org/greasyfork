require 'active_support/concern'

# Devise seems to handle log-in-then-go-to fine for Rails stuff, but not for the forum. This adds support
# via a "return_to" parameter.
module LoginMethods
  extend ActiveSupport::Concern

  included do
    prepend_before_action :store_location
  end

  def store_location
    return if params[:return_to].nil?

    v = clean_redirect_param(:return_to)
    return if v.nil?

    if v.bytesize > SafeStoreLocation::MAX_LOCATION_SIZE
      session.delete(:user_return_to)
      Rails.logger.warn("Discarding oversized sign-in return location (#{v.bytesize} bytes)")
    else
      session[:user_return_to] = v
    end
  end
end
