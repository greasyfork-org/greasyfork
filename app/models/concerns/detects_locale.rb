module DetectsLocale
  def detect_locale
    ft = full_text
    return if ft.nil?

    if Greasyfork::Application.config.enable_detect_locale
      begin
        # Metered on number of requests and bytes.
        dl_lang_code = DetectLanguage.simple_detect(ft[0...1000])
      rescue StandardError => e
        Rails.logger.error "Could not detect language - #{e}"
      end
      unless dl_lang_code.nil?
        locale = Locale.fetch_locale(dl_lang_code)
        return locale if locale

        Rails.logger.error "detect_language gave unrecognized code #{dl_lang_code}"
      end
    end
    # assume english
    Locale.english
  end
end
