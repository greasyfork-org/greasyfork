module Admin
  class AdsController < BaseController
    DISALLOWED_INCLUDES = %w[youtube google].freeze
    DISALLOWED_KEYWORDS = (%w[hack crack 破解] + DISALLOWED_INCLUDES).freeze

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

    def approve
      Script.find(params[:id]).update(adsense_approved: true)
      redirect_to pending_admin_ads_path
    end

    def reject
      Script.find(params[:id]).update(adsense_approved: false)
      redirect_to pending_admin_ads_path
    end

    private

    def disallowed_keyword_regexp
      @disallowed_keyword_regexp ||= Regexp.new(DISALLOWED_KEYWORDS.map { |keyword| Regexp.escape(keyword) }.join('|'), true)
    end

    def contains_disallowed_keyword?(script)
      script.localized_attributes.any? { |la| disallowed_keyword_regexp.match?(la.attribute_value) }
    end
    helper_method :contains_disallowed_keyword?
  end
end
