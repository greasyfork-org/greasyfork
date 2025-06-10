Rails.application.config.after_initialize do
  Locale.load_locale_cache
end
