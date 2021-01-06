class CommentNotificationJob < ApplicationJob
  def perform(comment)
    return if comment.soft_deleted?

    comment.send_notifications!
  end
end
