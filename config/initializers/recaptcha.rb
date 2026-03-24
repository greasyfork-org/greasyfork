Recaptcha.configure do |config|
  config.site_key = Rails.application.credentials.google.recaptcha_site_key
  config.enterprise = true
  config.enterprise_api_key = Rails.application.credentials.google.api_key
  config.enterprise_project_id = Rails.application.credentials.google.project_id
end
