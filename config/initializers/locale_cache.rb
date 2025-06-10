ActiveSupport.on_load(:active_record) do
  Locale.load_locale_cache
end
