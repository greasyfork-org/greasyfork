class CommentSpamCheckJob < ApplicationJob
  queue_as :low

  def perform(comment, ip, user_agent, referrer, content_digest = nil)
    return if comment.soft_deleted?

    CommentCheckingService.check(comment, ip:, user_agent:, referrer:, content_digest:)
  end
end
