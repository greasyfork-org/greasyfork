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
                    &.select { |sq| sq.item['wrapped'] == name } || []
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

    # Returns true if a job matching the args is enqueued, scheduled, or will be retried.
    def will_run_with_args?(*args)
      currently_enqueued_with_args?(*args) ||
        currently_scheduled_with_args?(*args) ||
        currently_will_retry_with_args?(*args)
    end

    def currently_running_with_args?(*args)
      currently_running.any? { |job_hash| job_hash_matches_args?(job_hash, *args) }
    end

    def currently_enqueued_with_args?(*args)
      currently_enqueued.any? { |job| job_hash_matches_args?(job.item, *args) }
    end

    def currently_scheduled_with_args?(*args)
      currently_scheduled.any? { |job| job_hash_matches_args?(job.item, *args) }
    end

    def currently_will_retry_with_args?(*args)
      currently_will_retry.any? { |job| job_hash_matches_args?(job.item, *args) }
    end

    def job_hash_matches_args?(job_hash, *args)
      job_args = job_hash['args'].first['arguments']
      check_args = ActiveJob::Arguments.serialize(args)
      job_args == check_args
    end

    # perform_later if a job matching the args is not already enqueued, scheduled, or running.
    def perform_later_unless_will_run(*args)
      begin
        will_run = will_run_with_args?(*args)
      rescue Redis::CannotConnectError => e
        raise e unless Rails.env.test?

        Rails.logger.warn('Redis not available, assuming this job is not enqueued.')
        will_run = false
      end

      if will_run
        Rails.logger.info("#{name} is already enqueued with args #{ActiveJob::Arguments.serialize(args)}, not enqueuing again.")
      else
        perform_later(*args)
      end
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
