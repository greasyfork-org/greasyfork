require 'sidekiq/max_concurrency_exception'

class ApplicationJob < ActiveJob::Base
  include Rails.application.routes.url_helpers

  self.queue_adapter = :sidekiq if Rails.env.production?

  retry_on(Sidekiq::MaxConcurrencyException, wait: 1.minute, jitter: 0.75, attempts: :unlimited)

  class << self
    attr_accessor :max_concurrency

    # Set the maximum number of processes that should be running this job at once. If this is exceeded,
    # Sidekiq::MaxConcurrencyException will be raised, and the job will be retried later.

    def enqueued?
      currently_running.any? || currently_enqueued.any? || currently_scheduled.any? || currently_will_retry.any?
    end

    # Returns an Array of Hashes.
    def currently_running
      Sidekiq::Workers
        .new
        .map { |_process_id, _thread_id, work| work['payload'] }
        .select { |p| p['wrapped'] == name }
    end

    # Returns an Array of Sidekiq::Job.
    def currently_enqueued
      Sidekiq::Queue.all
                    .find { |queue| queue.name == queue_name }
                    .select { |sq| sq.item['wrapped'] == name }
    end

    # Returns an Array of Sidekiq::Job.
    def currently_scheduled
      Sidekiq::ScheduledSet.new.select { |sq| sq.item['wrapped'] == name }
    end

    def currently_will_retry
      Sidekiq::RetrySet.new.select { |sq| sq.item['wrapped'] == name }
    end

    def at_least_count_running?(count)
      i = 0
      Sidekiq::Workers
        .new
        .each do |_process_id, _thread_id, work|
          if work['payload']['wrapped'] == name
            i += 1
            return true if i >= count
          end
        end
      false
    end
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
