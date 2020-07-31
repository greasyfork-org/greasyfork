class ApplicationJob < ActiveJob::Base
  include Rails.application.routes.url_helpers

  self.queue_adapter = :sidekiq if Rails.env.production?

  def self.enqueued?
    currently_running.any? || currently_enqueued.any? || currently_scheduled.any?
  end

  # Returns an Array of Hashes.
  def self.currently_running
    Sidekiq::Workers
      .new
      .map { |_process_id, _thread_id, work| work['payload'] }
      .select { |p| p['wrapped'] == name }
  end

  # Returns an Array of Sidekiq::Job.
  def self.currently_enqueued
    Sidekiq::Queue.all
                  .map { |queue| queue.select { |sq| sq.item['wrapped'] == name } }
                  .flatten
  end

  # Returns an Array of Sidekiq::Job.
  def self.currently_scheduled
    Sidekiq::ScheduledSet.new.select { |sq| sq.item['wrapped'] == name }
  end

  protected

  def default_url_options
    Rails.application.routes.default_url_options
  end
end
