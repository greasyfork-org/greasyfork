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
end
