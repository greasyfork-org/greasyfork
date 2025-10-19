require 'test_helper'

class CommentCheckingServiceTest < ActiveSupport::TestCase
  test 'when none match' do
    mock_comment_spam_results
    comment = comments(:script_comment)

    assert_no_changes -> { Report.count } do
      CommentCheckingService.check(comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot')
    end

    assert_not comment.reload.soft_deleted?
    assert_nil comment.discussion.review_reason
    assert_equal CommentCheckingService::STRATEGIES.count, comment.comment_check_results.count
  end

  test 'when one matches' do
    mock_comment_spam_results(CommentChecking::AkismetChecker)

    comment = comments(:script_comment)

    assert_difference -> { Report.count } => 1 do
      CommentCheckingService.check(comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot')
    end
    assert Report.last.pending?
    assert_equal Discussion::REVIEW_REASON_RAINMAN, comment.discussion.review_reason
    assert_equal CommentCheckingService::STRATEGIES.count, comment.comment_check_results.count
    assert_equal 1, comment.comment_check_results.where(result: :spam).count
  end

  test 'when multiple match for an existing user' do
    mock_comment_spam_results(CommentChecking::AkismetChecker, CommentChecking::CustomChecker)

    comment = comments(:script_comment)
    comment.poster.update!(created_at: 1.month.ago)

    assert_difference -> { Report.count } => 1 do
      CommentCheckingService.check(comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot')
    end
    assert_not comment.reload.soft_deleted?
    assert Report.last.pending?
    assert_equal Discussion::REVIEW_REASON_RAINMAN, comment.discussion.review_reason
    assert_equal 2, comment.comment_check_results.where(result: :spam).count
  end

  test 'when multiple match for a new user' do
    mock_comment_spam_results(CommentChecking::AkismetChecker, CommentChecking::CustomChecker)

    comment = comments(:script_comment)
    comment.poster.update!(created_at: 1.day.ago)

    assert_difference -> { Report.count } => 1 do
      CommentCheckingService.check(comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot')
    end
    assert Report.last.upheld?
    assert comment.reload.soft_deleted?
    assert comment.poster.reload.banned?
    assert_nil comment.discussion.review_reason
    assert_equal 2, comment.comment_check_results.where(result: :spam).count
  end

  def mock_comment_spam_results(*spam_returning_strategies)
    CommentCheckingService::STRATEGIES.each { |strategy_class| strategy_class.any_instance.expects(:skip?).returns(false) }
    non_spam_returning_strategies = CommentCheckingService::STRATEGIES - spam_returning_strategies
    non_spam_returning_strategies.each { |strategy_class| strategy_class.any_instance.expects(:check).returns(CommentChecking::Result.not_spam(strategy_class.new(nil, ip: nil, referrer: nil, user_agent: nil))) }
    spam_returning_strategies.each { |strategy_class| strategy_class.any_instance.expects(:check).returns(CommentChecking::Result.new(true, strategy: strategy_class.new(nil, ip: nil, referrer: nil, user_agent: nil))) }
  end
end
