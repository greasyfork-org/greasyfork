require 'discussion_converter'

class DiscussionConversionJob < ApplicationJob
  queue_as :default

  def perform(forum_discussion_id)
    Discussion.transaction do
      forum_discussion = ForumDiscussion.find(forum_discussion_id)
      new_discussion = DiscussionConverter.convert(forum_discussion)
      new_discussion.save!
      forum_discussion.forum_comments.create!(Body: "This discussion has been migrated to <a href=\"#{new_discussion.url}\">#{new_discussion.url}</a>", Format: 'Html', InsertUserID: 1, DateInserted: Time.now)
      forum_discussion.update_columns(Closed: 1)
    end
  end
end
