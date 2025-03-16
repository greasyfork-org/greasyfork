module Admin
  class AdsController < BaseController
    DISALLOWED_KEYWORDS = [
      'hack',
      'crack',
      '破解', # "Cracking"
      '去广告', # "Remove advertising"
      '无广告', # "No ads"
      '广告跳过', # "Advertisement skipped"
      '屏蔽广告', # "Block ads"
      'youtube',
      'google',
    ].freeze

    before_action :administrators_only

    layout 'list'

    def pending
      @scripts = Script
                 .active(:greasyfork)
                 .includes(:site_applications, :localized_attributes)
                 .where(adsense_approved: nil)
                 .order(page_views: :desc)
                 .limit(25)
    end

    def rejected
      @scripts = Script
                 .active(:greasyfork)
                 .includes(:site_applications, :localized_attributes)
                 .where(adsense_approved: false)
                 .order(page_views: :desc)
                 .limit(100)
      @return_to = rejected_admin_ads_path
      render 'pending'
    end

    def approve
      Script.find(params[:id]).update(adsense_approved: true)
      redirect_to params[:return_to] || pending_admin_ads_path
    end

    def reject
      Script.find(params[:id]).update(adsense_approved: false)
      redirect_to pending_admin_ads_path
    end

    private

    def ads_disallowed_keywords_used(script)
      used = Set.new
      script.localized_attributes.each do |la|
        text = ApplicationController.helpers.format_user_text_as_plain(la.attribute_value, la.value_markup).downcase
        used |= DISALLOWED_KEYWORDS.select do |keyword|
          text.include?(keyword)
        end
      end
      used
    end
    helper_method :ads_disallowed_keywords_used
  end
end
