Rails.application.config.script_page_cache_directory = Rails.root.join('tmp/cached_pages')
Rails.application.config.script_page_cache_expiry = 15.minutes
Rails.application.config.cached_code_path = Rails.root.join('tmp/cached_code')
Rails.application.config.cached_code_404_path = Rails.root.join('tmp/cached_code_404')
