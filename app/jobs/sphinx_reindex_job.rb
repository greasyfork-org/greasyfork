class SphinxReindexJob < ApplicationJob
  def perform
    ThinkingSphinx::RakeInterface.new.sql.index
  end
end
