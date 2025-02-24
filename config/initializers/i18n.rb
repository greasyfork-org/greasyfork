I18n.config.enforce_available_locales = true
# locales good enough to link to
# names from https://api.drupal.org/api/drupal/includes!iso.inc/function/_locale_get_predefined_list/7
Rails.application.config.available_locales = { 'ar' => 'العَرَبِيةُ', 'bg' => 'Български', 'ckb' => 'کوردیی ناوەندی', 'cs' => 'Čeština', 'da' => 'Dansk', 'de' => 'Deutsch', 'el' => 'Ελληνικά', 'en' => 'English', 'eo' => 'Esperanto', 'es' => 'Español', 'es-419' => 'Español latinoaméricano', 'fi' => 'Suomi', 'fr' => 'Français', 'fr-CA' => 'Français canadien', 'he' => 'עברית', 'hr' => 'Hrvatski', 'hu' => 'Magyar', 'id' => 'Bahasa Indonesia', 'it' => 'Italiano', 'ja' => '日本語', 'ka' => 'ქართული ენა', 'ko' => '한국어', 'mr' => 'मराठी', 'nb' => 'Bokmål', 'nl' => 'Nederlands', 'pl' => 'Polski', 'pt-BR' => 'Português do Brasil', 'ro' => 'Română', 'ru' => 'Русский', 'sk' => 'Slovenčina', 'sr' => 'srpski', 'sv' => 'Svenska', 'th' => 'ภาษาไทย', 'tr' => 'Türkçe', 'uk' => 'Українська', 'ug' => 'ئۇيغۇرچە', 'vi' => 'Tiếng Việt', 'zh-CN' => '简体中文', 'zh-TW' => '繁體中文' }
Rails.application.config.help_translate_url = 'https://github.com/greasyfork-org/greasyfork/wiki/Translating-Greasy-Fork'
Rails.application.config.i18n.fallbacks = [:en]

# https://support.google.com/admanager/answer/9727
Rails.application.config.no_adsense_locales = ['eo']
