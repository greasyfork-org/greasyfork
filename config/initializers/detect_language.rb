DetectLanguage.configure do |config|
  config.api_key = Rails.application.credentials.detect_language_api_key
end
