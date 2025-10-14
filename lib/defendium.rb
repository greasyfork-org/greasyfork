class Defendium
  END_POINT = URI('https://api.defendium.com/check')

  def initialize(api_key)
    @api_key = api_key
  end

  def check(content:, content_type: nil, ip: nil, url: nil, user_agent: nil, referrer: nil, author: nil, author_email: nil, author_url: nil, languages: nil, charset: 'UTF-8')
    data = {
      secret_key: @api_key,
      content:,
      content_type:,
      ip:,
      url:,
      user_agent:,
      referrer:,
      author:,
      author_email:,
      languages:,
      charset:,
    }

    http = Net::HTTP.new(END_POINT.host, END_POINT.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER

    request = Net::HTTP::Post.new(END_POINT.path, 'Content-Type' => 'application/json')
    request.body = data.to_json
    response = http.request(request)

    # Process the response
    case response
    when Net::HTTPSuccess
      JSON.parse(response.body)['result']
    else
      Sentry.capture_message("Defendium request failed: #{response.code} #{response.body}", extra: data.except(:api_key))
      false
    end
  end
end
