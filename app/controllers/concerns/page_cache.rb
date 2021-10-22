module PageCache
  def cache_page(page_key, &block)
    if page_key.nil? || current_user
      html = yield
      render html: html
      return
    end

    html = Rails.cache.fetch(page_key, expires_in: 1.minute, &block)
    render html: html
  end
end
