require 'test_helper'

class OnlyLinkCheckerCheckerTest < ActiveSupport::TestCase
  test 'when it is a single link by a new user' do
    comment = comments(:script_comment)
    comment.update!(text: 'https://example.com/')
    comment.poster.update!(created_at: 1.day.ago)

    assert CommentChecking::OnlyLinkChecker.check(comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot').spam?
  end

  test 'when it is a single internal link by a new user' do
    comment = comments(:script_comment)
    comment.update!(text: 'https://greasyfork.org/')
    comment.poster.update!(created_at: 1.day.ago)

    assert_not CommentChecking::OnlyLinkChecker.check(comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot').spam?
  end

  test 'when it is a single link by an existing user' do
    comment = comments(:script_comment)
    comment.update!(text: 'https://example.com/')
    comment.poster.update!(created_at: 1.month.ago)

    assert_not CommentChecking::OnlyLinkChecker.check(comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot').spam?
  end

  test 'when it is a multiple links by a new user' do
    comment = comments(:script_comment)
    comment.update!(text: "https://example.com/\nhttps://example.com/\nhttps://example.com/")
    comment.poster.update!(created_at: 1.day.ago)

    assert CommentChecking::OnlyLinkChecker.check(comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot').spam?
  end

  test 'when it is a link and more text by a new user' do
    comment = comments(:script_comment)
    comment.update!(text: 'visit this site: https://example.com/')
    comment.poster.update!(created_at: 1.day.ago)

    assert_not CommentChecking::OnlyLinkChecker.check(comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot').spam?
  end
end
