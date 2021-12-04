module ShowsAds
  def choose_ad_method
    no_ads = general_ads_setting
    return no_ads if no_ads

    AdMethod.ga
  end

  def choose_ad_method_for_script(script)
    no_ads = general_ads_setting
    return no_ads if no_ads

    return AdMethod.no_ad(:script_deleted) if script.nil? || script.deleted?

    return AdMethod.no_ad(:sensitive) if script&.sensitive

    return AdMethod.ga if script.adsense_approved && locale_allows_adsense? && script.localized_attributes.where(attribute_key: 'additional_info').any?

    [AdMethod.ca, AdMethod.ea].sample
  end

  def choose_ad_method_for_scripts(scripts)
    no_ads = general_ads_setting
    return no_ads if no_ads

    # #size, not #count, here because #count does things wrong with will_paginate, which is used when this is filtered
    # by a ScriptSet.
    # https://github.com/mislav/will_paginate/issues/449
    return AdMethod.no_ad(:not_enough_scripts) if scripts.size < 3
    return AdMethod.no_ad(:sensitive_list) if scripts.any?(&:sensitive?)

    AdMethod.ea
  end

  def general_ads_setting
    return AdMethod.no_ad(:test) if Rails.env.test?
    return AdMethod.no_ad(:sleazy) if sleazy?
    return AdMethod.no_ad(:user_pref) if current_user && !current_user.show_ads
  end

  def locale_allows_adsense?
    Rails.application.config.no_adsense_locales.exclude?(request_locale.code)
  end
end
