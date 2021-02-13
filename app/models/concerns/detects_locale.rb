module DetectsLocale
  def detect_locale
    ft = full_text
    return if ft.nil?

    if Greasyfork::Application.config.enable_detect_locale
      begin
        dl_lang_code = DetectLanguage.simple_detect(ft)
      rescue StandardError => e
        Rails.logger.error "Could not detect language - #{e}"
      end
      unless dl_lang_code.nil?
        locales = Locale.where(detect_language_code: dl_lang_code)
        return locales.first unless locales.empty?

        Rails.logger.error "detect_language gave unrecognized code #{dl_lang_code}"
      end
    end
    # assume english
    Locale.english
  end
end
