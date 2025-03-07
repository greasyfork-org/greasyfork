require 'test_helper'

class CustomCheckerTest < ActiveSupport::TestCase
  test 'when it matches the pattern' do
    comment = comments(:script_comment)
    comment.update!(text: 'CDB Keto 🐧')

    assert CommentChecking::CustomChecker.check(comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot').spam?
  end

  test 'when it does not match the pattern' do
    comment = comments(:script_comment)
    comment.update!(text: 'normal content')

    assert_not CommentChecking::CustomChecker.check(comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot').spam?
  end
end
