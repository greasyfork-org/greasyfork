class AdMethod
  attr_accessor(:ad_method, :no_ad_reason)

  def initialize(ad_method, no_ad_reason = nil)
    @ad_method = ad_method
    @no_ad_reason = no_ad_reason
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

  def ev?
    @ad_method == 'ev'
  end

  def cd?
    @ad_method == 'cd'
  end

  def self.ga
    new('ga')
  end

  def self.ea
    new('ea')
  end

  def self.ev
    new('ev')
  end

  def self.cd
    new('cd')
  end

  def self.no_ad(reason)
    new(nil, reason)
  end
end
