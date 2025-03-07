require 'test_helper'

class AkismetCheckerTest < ActiveSupport::TestCase
  test "when it's not spam" do
    comment = comments(:script_comment)

    Akismet.expects(:api_key).returns('123')
    Akismet.expects(:check).returns([false, false])

    assert_not CommentChecking::AkismetChecker.check(comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot').spam?
  end

  test 'when it is akismet spam' do
    comment = comments(:script_comment)

    Akismet.expects(:api_key).returns('123')
    Akismet.expects(:check).returns([true, false])

    assert CommentChecking::AkismetChecker.check(comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot').spam?
  end
end
