require 'sidekiq/max_concurrency_exception'
require 'sidekiq/queue_checking'

class ApplicationJob < ActiveJob::Base
  include Rails.application.routes.url_helpers
  include Sidekiq::QueueChecking

  self.queue_adapter = :sidekiq if Rails.env.production?

  retry_on(Sidekiq::MaxConcurrencyException, wait: 1.minute, jitter: 0.75, attempts: :unlimited)

  class << self
    # Set the maximum number of processes that should be running this job at once. If this is exceeded,
    # Sidekiq::MaxConcurrencyException will be raised, and the job will be retried later.
    attr_accessor :max_concurrency
  end

  def perform_now
    # Will get caught by retry_on.
    raise Sidekiq::MaxConcurrencyException, "#{self.class.max_concurrency} #{self.class.name} processes already running." if !Rails.env.test? && self.class.max_concurrency && self.class.at_least_count_running?(self.class.max_concurrency)

    super
  end

  protected

  def default_url_options
    Rails.application.routes.default_url_options
  end
end
