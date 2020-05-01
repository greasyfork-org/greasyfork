class ScriptDeleteJob < ApplicationJob
  queue_as :low

  def perform
    # Delete callbacks don't work on a remote Sphinx. We don't need that anyway, as these already don't show in search results.
    ThinkingSphinx::Callbacks.suspend do
      Script.where.not(permanent_deletion_request_date: nil).where(['permanent_deletion_request_date < ?', 7.days.ago]).each(&:destroy)
      Script.where(locked: true).where.not(script_delete_type_id: nil).where(['deleted_at < ?', 1.year.ago]).limit(100).each(&:destroy)
    end
    self.class.set(wait: 1.hour).perform_later
  end
end
