module ShowsAds
  def choose_ad_method
    return nil unless ads_enabled?
    'ga'
  end

  def eligible_for_ads?(script=nil)
    return ads_enabled? && !script&.sensitive
  end

  def choose_ad_method_for_script(script)
    return nil unless eligible_for_ads?(script)
    return 'cf' if script.localized_attributes.where(attribute_key: 'additional_info').none?
    script.adsense_approved ? 'ga' : 'cf'
  end

  def choose_ad_method_for_scripts(scripts)
    return nil unless ads_enabled?
    return nil if scripts.count < 3
    return nil if scripts.any?(&:sensitive?)
    return 'ga' if scripts.all?(&:adsense_approved)
    'cf'
  end

  private

  def ads_enabled?
    return false if Rails.env.test?
    return false if sleazy?
    current_user.nil? || current_user.show_ads
  end

  #FALLBACK_METHODS = ['ca', 'cf']

  #def fallback_ad_method
  #  FALLBACK_METHODS.sample
  #end
end
