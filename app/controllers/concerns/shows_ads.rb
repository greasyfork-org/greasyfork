module ShowsAds
  def choose_ad_method(script=nil)
    return nil if Rails.env.test?
    return nil if sleazy?
    return nil if script&.sensitive
    return nil if current_user && !current_user.show_ads
    return 'ga' if script.nil?
    return 'ca' if script.localized_attribute_for('additional_info', I18n.locale).blank?
    return script.adsense_approved ? 'ga' : 'ca'
  end
end
