require 'net/http'

class GoogleSafeBrowsing
  def self.check(urls)
    return [] if urls.empty?
    return [] unless Rails.application.secrets.google_safe_browsing_api_key

    uri = URI("https://safebrowsing.googleapis.com/v4/threatMatches:find?key=#{Rails.application.secrets.google_safe_browsing_api_key}")
    body = {
      client: {
        clientId: 'Greasy Fork',
        clientVersion: '0.1',
      },
      threatInfo: {
        threatTypes: %w[MALWARE SOCIAL_ENGINEERING UNWANTED_SOFTWARE POTENTIALLY_HARMFUL_APPLICATION],
        platformTypes: ['ANY_PLATFORM'],
        threatEntryTypes: ['URL'],
        threatEntries: urls.map do |url|
          { url: url }
        end,
      },
    }
    res = Net::HTTP.post(uri, body.to_json, 'Content-Type' => 'application/json')
    results = JSON.parse(res.body)
    return [] if results['matches'].nil?

    results['matches'].map { |m| m['threat']['url'] }
  end
end
