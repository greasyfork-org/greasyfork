class ScriptDiscussionConversionQueueingJob < ApplicationJob
  queue_as :low

  def perform
    script = Script.where(use_new_discussions: false).order(:id).first
    return unless script

    script.users.first.scripts.pluck(:id).each do |script_id|
      ScriptDiscussionConversionJob.perform_later(script_id)
    end
  end
end
