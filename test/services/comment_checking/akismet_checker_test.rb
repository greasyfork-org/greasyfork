require 'test_helper'

class AkismetCheckerTest < ActiveSupport::TestCase
  test "when it's not spam" do
    comment = comments(:script_comment)

    Akismet.expects(:check).returns([false, false])

    assert_not CommentChecking::AkismetChecker.new(comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot').check.spam?
  end

  test 'when it is akismet spam' do
    comment = comments(:script_comment)

    Akismet.expects(:check).returns([true, false])

    assert CommentChecking::AkismetChecker.new(comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot').check.spam?
  end

  test 'reuses a submission only for the current text' do
    comment = comments(:script_comment)
    checker = CommentChecking::AkismetChecker.new(comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot')
    Akismet.expects(:check).twice.returns([false, false], [true, false])

    assert_not checker.check.spam?
    assert_not checker.check.spam?
    comment.update!(text: 'edited spam')
    assert checker.check.spam?
  end
end
