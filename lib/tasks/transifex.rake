require 'yaml'

namespace :transifex do
  def get_data_from_transifex(url)
    require 'uri'
    require 'net/http'
    require 'openssl'

    url = URI(url)

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(url)
    request['accept'] = 'application/vnd.api+json'
    request['authorization'] = "Bearer #{Rails.application.credentials.transifex_api_key!}"

    response = http.request(request)
    body = JSON.parse(response.read_body)

    data = body['data']
    if (next_cursor = body.dig('links', 'next'))
      return data + get_data_from_transifex(next_cursor)
    end

    data
  end

  def from_transifex_locale(locale)
    locale.sub('_', '-')
  end

  task update_meta: [:update_stats, :update_contributors]

  task update_stats: :environment do
    get_data_from_transifex('https://rest.api.transifex.com/resource_language_stats?filter[project]=o:greasy-fork:p:greasy-fork').each do |lang_data|
      locale_code = from_transifex_locale(lang_data['id'].split(':').last)
      percent = lang_data['attributes']['translated_strings'] * 100 / lang_data['attributes']['total_strings']

      if percent == 0
        Rails.logger.info("Locale #{locale_code} empty, skipping")
        next
      end

      locale = Locale.find_by(code: locale_code)
      if locale.nil?
        Rails.logger.warn("Unknown locale #{locale_code}, skipping")
        next
      end

      locale.update!(percent_complete: percent)
    end
  end

  task update_contributors: :environment do
    contributors = {}
    get_data_from_transifex('https://rest.api.transifex.com/team_memberships?filter[organization]=o:greasy-fork').each do |member_data|
      locale_code = from_transifex_locale(member_data.dig('relationships', 'language', 'data', 'id').delete_prefix('l:'))
      user_name = member_data.dig('relationships', 'user', 'data', 'id').delete_prefix('u:')
      contributors[locale_code] ||= []
      contributors[locale_code] << user_name
    end
    contributors.each do |locale_code, users|
      locale = Locale.find_by(code: locale_code)
      if locale.nil?
        Rails.logger.warn("Unknown locale #{locale_code}, skipping")
        next
      end

      locale.locale_contributors.delete_all
      users.uniq.each do |user|
        LocaleContributor.create(locale:, transifex_user_name: user)
      end
    end
  end
end
