module Admin
  class AdsController < BaseController
    DISALLOWED_INCLUDES = ['youtube', 'google']

    def pending
      @scripts = Script
        .active(:greasyfork)
        .includes(:site_applications)
        .where(adsense_approved: nil)
        .order(page_views: :desc)
        .limit(25)
    end

    def approve
      Script.find(params[:id]).update(adsense_approved: true)
      redirect_to pending_admin_ads_path
    end

    def reject
      Script.find(params[:id]).update(adsense_approved: false)
      redirect_to pending_admin_ads_path
    end
  end
end
