class CommentNotificationJob < ApplicationJob
  def perform(comment)
    return if comment.nil? || comment.soft_deleted? || comment.review_reason.present? || comment.discussion.review_reason.present?

    comment.send_notifications!
  end
end
