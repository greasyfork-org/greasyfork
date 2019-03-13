module ShowsAds
  def choose_ad_method
    return nil unless ads_enabled?
    'ga'
  end

  def choose_ad_method_for_script(script)
    return nil unless ads_enabled?
    return nil if script.sensitive
    return fallback_ad_method if script.localized_attribute_for('additional_info', I18n.locale).blank?
    script.adsense_approved ? 'ga' : fallback_ad_method
  end

  def choose_ad_method_for_scripts(scripts)
    return nil unless ads_enabled?
    return nil if scripts.count < 3
    return nil if scripts.any?(&:sensitive?)
    return 'ga' if scripts.all?(&:adsense_approved)
    fallback_ad_method
  end

  private

  def ads_enabled?
    return false if Rails.env.test?
    return false if sleazy?
    current_user.nil? || current_user.show_ads
  end

  FALLBACK_METHODS = ['ca'] * 9 + ['cf']

  def fallback_ad_method
    FALLBACK_METHODS.sample
  end
end
