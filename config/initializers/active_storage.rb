Rails.application.config.to_prepare do
  ActiveStorage::AnalyzeJob.retry_on ActiveRecord::StatementInvalid, wait: 2.seconds, attempts: 5
end
