class CommentNotificationJob < ApplicationJob
  def perform(comment)
    return if comment.soft_deleted? || comment.discussion.review_reason.present?

    comment.send_notifications!
  end
end
