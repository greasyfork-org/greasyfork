module ShowsAds
  extend ActiveSupport::Concern

  def choose_ad_method
    no_ads = general_ads_setting
    return no_ads if no_ads

    return AdMethod.rb if sleazy?

    AdMethod.ga
  end

  def choose_ad_method_for_script(script, allow_ga: true)
    no_ads = general_ads_setting
    return no_ads if no_ads

    return AdMethod.no_ad(:script_deleted) if script.nil? || script.deleted?

    return AdMethod.rb if sleazy?

    return AdMethod.no_ad(:sensitive) if script&.sensitive

    return AdMethod.ga if allow_ga && script.adsense_approved && locale_allows_adsense? && (script.additional_info || script.newest_saved_script_version.attachments.any? || script.similar_scripts(script_subset:, locale: I18n.locale).any?)

    AdMethod.ea(variant: (request_locale.code unless valid_locale_for_ea?))
  end

  def choose_ad_method_for_post_install(script)
    choose_ad_method_for_script(script, allow_ga: false)
  end

  def choose_ad_method_for_scripts(scripts)
    no_ads = general_ads_setting
    return no_ads if no_ads

    return AdMethod.rb if sleazy?

    return AdMethod.no_ad(:sensitive_list) if scripts.any?(&:sensitive?)

    AdMethod.ea(variant: (request_locale.code unless valid_locale_for_ea?))

    # Not great RPM here, but we got nothing else
    # return AdMethod.ga if scripts.all?(&:adsense_approved)
  end

  def choose_ad_method_for_discussion(discussion)
    no_ads = general_ads_setting

    return no_ads if no_ads

    return AdMethod.rb if sleazy?

    return AdMethod.no_ad(:sensitive) if discussion.script&.sensitive?

    AdMethod.ea(variant: (request_locale.code unless valid_locale_for_ea?))
  end

  def choose_ad_method_for_error_page
    no_ads = general_ads_setting
    return no_ads if no_ads

    return AdMethod.rb if sleazy?

    AdMethod.ea(variant: (request_locale.code unless valid_locale_for_ea?))
  end

  def choose_ad_method_for_user(displayed_scripts:)
    no_ads = general_ads_setting
    return no_ads if no_ads

    return AdMethod.rb if sleazy?

    return AdMethod.no_ad(:sensitive_list) if displayed_scripts.where(sensitive: true).any?

    # EA performs better here
    # return AdMethod.ga if user.scripts.all?(&:adsense_approved)

    AdMethod.ea(variant: (request_locale.code unless valid_locale_for_ea?))
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

  def rb_site_wide_exception?
    [
      ['home', 'index'],
      ['scripts', 'show'],
      ['scripts', 'post_install'],
      ['script_versions', 'index'],
      ['users', 'show'],
    ].include?([controller_name, action_name])
  end

  included do
    helper_method :general_ads_setting, :valid_locale_for_ea?, :rb_site_wide_exception?
  end
end
