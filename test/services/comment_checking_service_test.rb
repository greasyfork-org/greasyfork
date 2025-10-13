require 'test_helper'

class CommentCheckingServiceTest < ActiveSupport::TestCase
  test 'when none match' do
    CommentCheckingService::STRATEGIES.each { |strategy| strategy.expects(:check).returns(CommentChecking::Result.not_spam(strategy)) }
    comment = comments(:script_comment)

    assert_no_changes -> { Report.count } do
      CommentCheckingService.check(comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot')
    end

    assert_not comment.reload.soft_deleted?
    assert_nil comment.discussion.review_reason
  end

  test 'when one matches' do
    matching_checkers = [CommentChecking::AkismetChecker]
    (CommentCheckingService::STRATEGIES - matching_checkers).each { |strategy| strategy.expects(:check).returns(CommentChecking::Result.not_spam(strategy)) }
    matching_checkers.each { |checker| checker.expects(:check).returns(CommentChecking::Result.new(true, strategy: checker)) }
    comment = comments(:script_comment)

    assert_difference -> { Report.count } => 1 do
      CommentCheckingService.check(comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot')
    end
    assert Report.last.pending?
    assert_equal Discussion::REVIEW_REASON_RAINMAN, comment.discussion.review_reason
  end

  test 'when multiple match for an existing user' do
    matching_checkers = [CommentChecking::AkismetChecker, CommentChecking::CustomChecker]
    (CommentCheckingService::STRATEGIES - matching_checkers).each { |strategy| strategy.expects(:check).returns(CommentChecking::Result.not_spam(strategy)) }
    matching_checkers.each { |checker| checker.expects(:check).returns(CommentChecking::Result.new(true, strategy: checker)) }

    comment = comments(:script_comment)
    comment.poster.update!(created_at: 1.month.ago)

    assert_difference -> { Report.count } => 1 do
      CommentCheckingService.check(comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot')
    end
    assert_not comment.reload.soft_deleted?
    assert Report.last.pending?
    assert_equal Discussion::REVIEW_REASON_RAINMAN, comment.discussion.review_reason
  end

  test 'when multiple match for a new user' do
    matching_checkers = [CommentChecking::AkismetChecker, CommentChecking::CustomChecker]
    (CommentCheckingService::STRATEGIES - matching_checkers).each { |strategy| strategy.expects(:check).returns(CommentChecking::Result.not_spam(strategy)) }
    matching_checkers.each { |checker| checker.expects(:check).returns(CommentChecking::Result.new(true, strategy: checker)) }

    comment = comments(:script_comment)
    comment.poster.update!(created_at: 1.day.ago)

    assert_difference -> { Report.count } => 1 do
      CommentCheckingService.check(comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot')
    end
    assert Report.last.upheld?
    assert comment.reload.soft_deleted?
    assert comment.poster.reload.banned?
    assert_nil comment.discussion.review_reason
  end
end
