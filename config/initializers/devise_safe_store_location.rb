# From https://gist.github.com/danielfone/c8ab593c326#a8052651c
# Prevent ActionDispatch::Cookies::CookieOverflow when redirected to sign-in from a long path.

module SafeStoreLocation
  # Cookies can be 4096, but this value is encrypted, and it may not be the only thing in the session.
  MAX_LOCATION_SIZE = 1024

  def store_location_for(resource_or_scope, location)
    super unless location && location.bytesize > MAX_LOCATION_SIZE
  end
end

Devise::FailureApp.include SafeStoreLocation
