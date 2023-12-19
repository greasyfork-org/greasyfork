if Rails.application.credentials.akismet
  Akismet.api_key = Rails.application.credentials.akismet[:api_key]
  Akismet.app_url = Rails.application.credentials.akismet[:app_url]
end
