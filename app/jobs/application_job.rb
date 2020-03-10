class ApplicationJob < ActiveJob::Base
  include Rails.application.routes.url_helpers

  self.queue_adapter = :delayed_job

  protected

  def default_url_options
    Rails.application.routes.default_url_options
  end

  def self.enqueued?
    return Sidekiq::Workers.new.any? {|process_id, thread_id, work| work['payload']['wrapped'] == self.name } ||
      Sidekiq::Queue.all.any? { |queue| queue.any? { |sq| sq.item['wrapped'] == self.name } }
  end
end