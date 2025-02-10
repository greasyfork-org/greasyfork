require 'google/analytics/data/v1beta'

class GoogleAnalytics
  SITE_TO_PROPERTY = {
    greasyfork: 'properties/293110681',
    sleazyfork: 'properties/293114118',
    cn_greasyfork: 'properties/477170299',
  }.freeze

  def self.report_installs(date, site: :greasyfork)
    # Create a request. To set request fields, pass in keyword arguments.
    # https://developers.google.com/analytics/devguides/reporting/data/v1/rest/v1beta/properties/runReport
    # https://www.rubydoc.info/gems/google-analytics-data-v1beta/0.4.1/Google/Analytics/Data/V1beta/RunReportRequest#dimension_filter-instance_method
    # https://developers.google.com/analytics/devguides/reporting/data/v1/basics#dimension_filters
    date_range = Google::Analytics::Data::V1beta::DateRange.new(start_date: date.iso8601, end_date: date.iso8601)
    metric = Google::Analytics::Data::V1beta::Metric.new(name: 'eventCount')
    dimension = Google::Analytics::Data::V1beta::Dimension.new(name: 'customEvent:script_id')
    filter = Google::Analytics::Data::V1beta::FilterExpression.new(filter: Google::Analytics::Data::V1beta::Filter.new(field_name: 'eventName', string_filter: Google::Analytics::Data::V1beta::Filter::StringFilter.new(match_type: Google::Analytics::Data::V1beta::Filter::StringFilter::MatchType::EXACT, value: 'Script install')))
    request = Google::Analytics::Data::V1beta::RunReportRequest.new(property: SITE_TO_PROPERTY[site], date_ranges: [date_range], metrics: [metric], dimensions: [dimension], dimension_filter: filter)

    # Call the run_report method.
    result = client.run_report request

    result.rows.to_h { |row| [row.dimension_values.first.value.to_i, row.metric_values.first.value.to_i] }
  end

  def self.report_pageviews(site: :greasyfork)
    date_range = Google::Analytics::Data::V1beta::DateRange.new(start_date: 30.days.ago.to_date.iso8601, end_date: Time.zone.today.iso8601)
    metric = Google::Analytics::Data::V1beta::Metric.new(name: 'screenPageViews')
    dimension = Google::Analytics::Data::V1beta::Dimension.new(name: 'pageLocation')

    results = []

    # Going with too many results at once gives an error.
    offset = 0
    limit = 25_000
    # Stop once we reach things with this many page views or less. Otherwise we can hit rate limits and otherwise spend
    # too much time on stuff that doesn't matter.
    minimum_to_query = 10

    loop do
      request = Google::Analytics::Data::V1beta::RunReportRequest.new(property: SITE_TO_PROPERTY[site], date_ranges: [date_range], metrics: [metric], dimensions: [dimension], limit:, offset:)

      # Call the run_report method.
      result = client.run_report request

      this_results = result.rows.map { |row| [row.dimension_values.first.value, row.metric_values.first.value.to_i] }
      return results if this_results.empty?

      results += this_results
      offset += limit

      return results if results.last.last <= minimum_to_query
    end
  end

  def self.client
    Google::Analytics::Data::V1beta::AnalyticsData::Client.new do |config|
      config.credentials = Rails.application.credentials.google_analytics.credentials!
    end
  end
end
