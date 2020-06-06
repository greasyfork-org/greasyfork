require 'discussion_converter'

class ScriptDiscussionConversionJob < ApplicationJob
  queue_as :default

  def perform(script_id)
    Script.transaction do
      script = Script.find(script_id)
      return if script.use_new_discussions
      script.discussions.each do |forum_discussion|
        new_discussion = DiscussionConverter.convert(forum_discussion)
        new_discussion.save!
      end
      script.update!(use_new_discussions: true)
    end
  end
end
