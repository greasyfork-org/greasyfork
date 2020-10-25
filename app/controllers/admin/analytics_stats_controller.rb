require 'csv'

module Admin
  class AnalyticsStatsController < BaseController
    before_action :administrators_only

    def show; end

    def update
      urls = {}
      Script.update_all(page_views: 0)
      CSV.new(params[:analytics_csv].read).each do |row|
        next if row.length < 2

        m = %r{.*/scripts/([0-9]+)-.*}.match(row[0])
        next if m.nil?

        urls[m[1]] = (urls[m[1]] || 0) + row[1].delete(',').to_i
      end
      urls.each do |script_id, page_views|
        Script.where(id: script_id).update_all(page_views: page_views)
      end
      flash[:notice] = 'Uploaded'
      redirect_to pending_admin_ads_path
    end
  end
end
