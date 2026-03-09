class AdMethod
  attr_accessor(:ad_method, :no_ad_reason, :variant)

  def initialize(ad_method, no_ad_reason: nil, variant: nil)
    @ad_method = ad_method
    @no_ad_reason = no_ad_reason
    @variant = variant
  end

  def show_ads?
    @ad_method.present?
  end

  def no_ads?
    !show_ads?
  end

  def css_class
    "ad-#{@ad_method}" if @ad_method
  end

  def tracking_key
    return @ad_method if @ad_method
    return "_#{@no_ad_reason}" if @no_ad_reason
  end

  def ga?
    @ad_method == 'ga'
  end

  def ea?
    @ad_method == 'ea'
  end

  def self.ga
    new('ga')
  end

  def self.ea(variant: nil)
    new('ea', variant:)
  end

  def self.no_ad(reason)
    new(nil, no_ad_reason: reason)
  end
end
