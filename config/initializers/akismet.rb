if Rails.application.secrets.akismet
  Akismet.api_key = Rails.application.secrets.akismet[:api_key]
  Akismet.app_url = Rails.application.secrets.akismet[:app_url]
end
