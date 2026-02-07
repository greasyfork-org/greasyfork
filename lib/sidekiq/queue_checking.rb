module Sidekiq
  module QueueChecking
    extend ActiveSupport::Concern

    class_methods do
      def runs_sidekiq?
        queue_adapter.is_a?(::ActiveJob::QueueAdapters.lookup(:sidekiq))
      end

      # Returns an Array of Sidekiq::Job.
      def currently_enqueued(any_queue: false)
        return [] unless runs_sidekiq?

        queues = if any_queue
                   Sidekiq::Queue.all
                 else
                   [Sidekiq::Queue.all.find { |queue| queue.name == queue_name }].compact
                 end
        queues.map { |queue| queue.select { |sq| sq.item['wrapped'] == name } }.flatten || []
      end

      # Returns an Array of Sidekiq::Job.
      def currently_scheduled
        return [] unless runs_sidekiq?

        Sidekiq::ScheduledSet.new.select { |sq| sq.item['wrapped'] == name }
      end

      def currently_will_retry
        return [] unless runs_sidekiq?

        Sidekiq::RetrySet.new.select { |sq| sq.item['wrapped'] == name }
      end

      def at_least_count_running?(count)
        return false unless runs_sidekiq?

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
      def will_run_in_any_queue_with_args?(*)
        return false unless runs_sidekiq?

        currently_enqueued_in_any_queue_with_args?(*) ||
          currently_scheduled_with_args?(*) ||
          currently_will_retry_with_args?(*)
      end

      # Returns true if a job matching the args is enqueued, scheduled, or will be retried.
      def will_run_with_args?(*)
        return false unless runs_sidekiq?

        currently_enqueued_with_args?(*) ||
          currently_scheduled_with_args?(*) ||
          currently_will_retry_with_args?(*)
      end

      def currently_enqueued_with_args?(*)
        return false unless runs_sidekiq?

        currently_enqueued.any? { |job| job_hash_matches_args?(job.item, *) }
      end

      def currently_enqueued_in_any_queue_with_args?(*)
        return false unless runs_sidekiq?

        currently_enqueued(any_queue: true).any? { |job| job_hash_matches_args?(job.item, *) }
      end

      def currently_scheduled_with_args?(*)
        return false unless runs_sidekiq?

        currently_scheduled.any? { |job| job_hash_matches_args?(job.item, *) }
      end

      def currently_will_retry_with_args?(*)
        return false unless runs_sidekiq?

        currently_will_retry.any? { |job| job_hash_matches_args?(job.item, *) }
      end

      def job_hash_matches_args?(job_hash, *args)
        job_args = job_hash['args'].first['arguments']
        check_args = ::ActiveJob::Arguments.serialize(args)
        job_args == check_args
      end

      # perform_later if a job matching the args is not already enqueued, scheduled, or running.
      def perform_later_unless_will_run(*args)
        begin
          will_run = will_run_with_args?(*args)
        rescue Redis::CannotConnectError => e
          raise e unless ::Rails.env.test?

          ::Rails.logger.warn('Redis not available, assuming this job is not enqueued.')
          will_run = false
        end

        if will_run
          ::Rails.logger.info("#{name} is already enqueued with args #{::ActiveJob::Arguments.serialize(args)}, not enqueuing again.")
        else
          perform_later(*args)
        end
      end

      # perform_later if a job matching the args is not already enqueued, scheduled, or running.
      def perform_later_unless_will_run_in_any_queue(*args)
        begin
          will_run = will_run_in_any_queue_with_args?(*args)
        rescue Redis::CannotConnectError => e
          raise e unless ::Rails.env.test?

          ::Rails.logger.warn('Redis not available, assuming this job is not enqueued.')
          will_run = false
        end

        if will_run
          ::Rails.logger.info("#{name} is already enqueued with args #{::ActiveJob::Arguments.serialize(args)}, not enqueuing again.")
        else
          perform_later(*args)
        end
      end
    end
  end
end
