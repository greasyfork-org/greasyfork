class ApplicationJob < ActiveJob::Base
  include Rails.application.routes.url_helpers

  self.queue_adapter = :delayed_job

  protected

  def default_url_options
    Rails.application.routes.default_url_options
  end
end