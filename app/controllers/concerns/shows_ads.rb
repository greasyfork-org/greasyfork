module ShowsAds
  def choose_ad_method
    return nil unless ads_enabled? && locale_allows_adsense?

    'ga'
  end

  def eligible_for_ads?(script = nil)
    return ads_enabled? && !script&.sensitive
  end

  def choose_ad_method_for_script(script)
    return nil unless eligible_for_ads?(script)

    return 'ga' if script.adsense_approved && locale_allows_adsense? && script.localized_attributes.where(attribute_key: 'additional_info').any?

    %w[ca ea].sample
  end

  def choose_ad_method_for_scripts(scripts)
    return nil unless ads_enabled?
    # #size, not #count, here because #count does things wrong with will_paginate, which is used when this is filtered
    # by a ScriptSet.
    # https://github.com/mislav/will_paginate/issues/449
    return nil if scripts.size < 3
    return nil if scripts.any?(&:sensitive?)

    # return 'ga' if scripts.all?(&:adsense_approved)

    'ea'
  end

  private

  def ads_enabled?
    return false if Rails.env.test?
    return false if sleazy?

    current_user.nil? || current_user.show_ads
  end

  def locale_allows_adsense?
    Rails.application.config.no_adsense_locales.exclude?(request_locale.code)
  end

  # FALLBACK_METHODS = ['ca', 'cf']

  # def fallback_ad_method
  #  FALLBACK_METHODS.sample
  # end
end
