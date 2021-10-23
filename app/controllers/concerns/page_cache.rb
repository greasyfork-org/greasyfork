module PageCache
  CSRF_META_TAGS = '<!-- csrf_meta_tags -->'.html_safe
  CSRF_TOKEN = '__CSRF_TOKEN__'.freeze
  IP_ADDRESS = '__IP_ADDRESS__'.freeze

  def cache_page(page_key)
    if page_key.nil? || current_user
      html = yield
      render html: html
      return
    end

    html = Rails.cache.fetch(page_key, expires_in: 1.minute) do
      @caching_request = true
      yield
    end

    response.set_header('X-Page-Cache', @caching_request ? 'write' : 'read')

    render html: html
      .gsub(CSRF_META_TAGS, view_context.csrf_meta_tags)
      .gsub(CSRF_TOKEN, session[:_csrf_token])
      .gsub(IP_ADDRESS, request.remote_ip)
      .html_safe
  end
end
