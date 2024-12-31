module ShowsAds
  def choose_ad_method
    no_ads = general_ads_setting
    return no_ads if no_ads

    return AdMethod.cd if sleazy?

    AdMethod.ga
  end

  def choose_ad_method_for_script(script)
    no_ads = general_ads_setting
    return no_ads if no_ads

    return AdMethod.no_ad(:script_deleted) if script.nil? || script.deleted?

    return AdMethod.cd if sleazy?

    return AdMethod.no_ad(:sensitive) if script&.sensitive

    return AdMethod.ga if script.adsense_approved && locale_allows_adsense? && (script.additional_info || script.newest_saved_script_version.attachments.any? || script.similar_scripts(script_subset:, locale: I18n.locale).any?)

    return AdMethod.ea if valid_locale_for_ea?

    AdMethod.cd
  end

  def choose_ad_method_for_scripts(scripts)
    no_ads = general_ads_setting
    return no_ads if no_ads

    return AdMethod.cd if sleazy?

    return AdMethod.no_ad(:sensitive_list) if scripts.any?(&:sensitive?)

    # #size, not #count, here because #count does things wrong with will_paginate, which is used when this is filtered
    # by a ScriptSet.
    # https://github.com/mislav/will_paginate/issues/449
    return AdMethod.ea if scripts.size < 3 && valid_locale_for_ea?

    return AdMethod.ga if scripts.all?(&:adsense_approved)

    return AdMethod.ea if valid_locale_for_ea?

    AdMethod.cd
  end

  private

  def general_ads_setting
    return AdMethod.no_ad(:test) if Rails.env.test?
    return AdMethod.no_ad(:user_pref) if current_user && !current_user.show_ads
  end

  def locale_allows_adsense?
    Rails.application.config.no_adsense_locales.exclude?(request_locale.code)
  end

  def valid_locale_for_ea?
    request_locale.code != 'zh-CN'
  end
end
