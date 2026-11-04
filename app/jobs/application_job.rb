require 'sidekiq/queue_checking'

class ApplicationJob < ActiveJob::Base
  include Rails.application.routes.url_helpers
  include Sidekiq::QueueChecking

  self.queue_adapter = :sidekiq if Rails.env.production?

  protected

  def default_url_options
    Rails.application.routes.default_url_options
  end
end
