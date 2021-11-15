require 'google/analytics/data/v1beta'

class GoogleAnalytics
  def self.report_installs(date, site: :greasyfork)
    # Create a client object. The client can be reused for multiple calls.
    client = Google::Analytics::Data::V1beta::AnalyticsData::Client.new do |config|
      config.credentials = Rails.application.secrets.google_analytics[:credentials]
    end

    # Create a request. To set request fields, pass in keyword arguments.
    # https://developers.google.com/analytics/devguides/reporting/data/v1/rest/v1beta/properties/runReport
    # https://www.rubydoc.info/gems/google-analytics-data-v1beta/0.4.1/Google/Analytics/Data/V1beta/RunReportRequest#dimension_filter-instance_method
    # https://developers.google.com/analytics/devguides/reporting/data/v1/basics#dimension_filters
    date_range = Google::Analytics::Data::V1beta::DateRange.new(start_date: date.iso8601, end_date: date.iso8601)
    metric = Google::Analytics::Data::V1beta::Metric.new(name: 'eventCount')
    dimension = Google::Analytics::Data::V1beta::Dimension.new(name: 'customEvent:script_id')
    filter = Google::Analytics::Data::V1beta::FilterExpression.new(filter: Google::Analytics::Data::V1beta::Filter.new(field_name: 'eventName', string_filter: Google::Analytics::Data::V1beta::Filter::StringFilter.new(match_type: Google::Analytics::Data::V1beta::Filter::StringFilter::MatchType::EXACT, value: 'Script install')))
    request = Google::Analytics::Data::V1beta::RunReportRequest.new(property: site == :sleazyfork ? 'properties/293114118' : 'properties/293110681', date_ranges: [date_range], metrics: [metric], dimensions: [dimension], dimension_filter: filter)

    # Call the run_report method.
    result = client.run_report request

    result.rows.map { |row| [row.dimension_values.first.value.to_i, row.metric_values.first.value.to_i] }.to_h
  end
end
