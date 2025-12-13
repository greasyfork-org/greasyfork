I18n.config.enforce_available_locales = true
# locales good enough to link to
Rails.application.config.available_locales = %w[ar be bg ckb cs da de el en eo es es-419 fi fr fr-CA he hr hu id it ja ka ko mr nb nl pl pt-BR ro ru sk sr sv th tr uk ug vi zh-CN zh-TW]
Rails.application.config.help_translate_url = 'https://github.com/greasyfork-org/greasyfork/wiki/Translating-Greasy-Fork'
Rails.application.config.i18n.fallbacks = [:en]

# https://support.google.com/admanager/answer/9727
Rails.application.config.no_adsense_locales = ['eo']
