class ApplicationJob < ActiveJob::Base
  include Rails.application.routes.url_helpers

  self.queue_adapter = :delayed_job

  def self.enqueued?
    return Sidekiq::Workers.new.any? { |_process_id, _thread_id, work| work['payload']['wrapped'] == name } ||
           Sidekiq::Queue.all.any? { |queue| queue.any? { |sq| sq.item['wrapped'] == name } } ||
           Sidekiq::ScheduledSet.new.any? { |sq| sq.item['wrapped'] == name }
  end

  protected

  def default_url_options
    Rails.application.routes.default_url_options
  end
end
