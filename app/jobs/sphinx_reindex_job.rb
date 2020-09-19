class SphinxReindexJob < ApplicationJob
  self.queue_adapter = :delayed_job

  def perform
    ThinkingSphinx::RakeInterface.new.sql.index
  end
end
