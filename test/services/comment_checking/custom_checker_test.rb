require 'test_helper'

class CustomCheckerTest < ActiveSupport::TestCase
  test 'when it matches text' do
    comment = comments(:script_comment)
    comment.update!(text: 'CDB Keto 🐧')

    assert CommentChecking::CustomChecker.new(comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot').check.spam?
  end

  test 'when it does not match text' do
    comment = comments(:script_comment)
    comment.update!(text: 'normal content')

    assert_not CommentChecking::CustomChecker.new(comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot').check.spam?
  end

  test 'when it matches pattern' do
    comment = comments(:script_comment)
    comment.update!(text: '{𝟣𝟪-𝟢𝟢𝟥-𝟤𝟥𝟢𝟣- 𝟩𝟢 } {U..E..}')

    assert CommentChecking::CustomChecker.new(comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot').check.spam?
  end
end
