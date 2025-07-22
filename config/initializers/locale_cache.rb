Rails.application.config.after_initialize do
  Locale.load_locale_cache if Locale.table_exists?
end
