class ScriptDiscussionConversionQueueingJob < ApplicationJob
  queue_as :low

  def perform
    scripts = Script.where(use_new_discussions: false).order(:id).limit(5)
    return unless script.any?

    scripts.map(&:users).flatten.uniq.map do |user|
      user.scripts.pluck(:id).each do |script_id|
        ScriptDiscussionConversionJob.perform_later(script_id)
      end
    end
  end
end
