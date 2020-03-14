require 'net/http'
require 'json'

class EmailCheckingService
  def self.check_user(user)
    return true if user.email.nil?
    return !user.disposable_email unless user.disposable_email.nil?

    user.update(disposable_email: !valid?(user.email))
    !user.disposable_email
  end

  def self.valid?(email)
    return true unless Rails.env.production?

    url = "https://open.kickbox.com/v1/disposable/url=#{URI.encode_www_form_component(email)}"
    uri = URI(url)
    response = Net::HTTP.get(uri)
    h = JSON.parse(response)
    !h['disposable']
  end
end
