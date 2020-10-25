module BrowserCaching
  # Disable caching so that browser 'back' navigation can't reach it without a reload, for example any page with
  # personal info. Note that this makes it so form field values are lost.
  def disable_browser_caching!
    response.headers['Cache-Control'] = 'no-cache, no-store, max-age=0, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = 'Fri, 01 Jan 1990 00:00:00 GMT'
  end
end
