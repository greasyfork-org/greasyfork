require 'test_helper'

class CommentSpamCheckJobTest < ActiveSupport::TestCase
  test 'it calls the spam checker' do
    comment = comments(:script_comment)
    CommentCheckingService.expects(:check).with(comment, ip: '127.0.0.1', user_agent: 'Bot', referrer: nil, content_digest: nil)
    CommentSpamCheckJob.perform_now(comment, '127.0.0.1', 'Bot', nil)
  end

  test 'it does nothing if the comment is deleted' do
    CommentCheckingService.expects(:check).never
    comment = comments(:script_comment)
    comment.update!(deleted_at: Time.zone.now)
    CommentSpamCheckJob.perform_now(comment, '127.0.0.1', 'Bot', nil)
  end

  test 'passes the queued content digest to the checker' do
    comment = comments(:script_comment)
    digest = comment.spam_check_digest
    CommentCheckingService.expects(:check).with(comment, ip: '127.0.0.1', user_agent: 'Bot', referrer: nil, content_digest: digest)

    CommentSpamCheckJob.perform_now(comment, '127.0.0.1', 'Bot', nil, digest)
  end
end
