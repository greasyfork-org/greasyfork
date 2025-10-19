require 'test_helper'

class OnlyLinkCheckerCheckerTest < ActiveSupport::TestCase
  test 'when it is a single link by a new user' do
    comment = comments(:script_comment)
    comment.update!(text: 'https://example.com/')
    comment.poster.update!(created_at: 1.day.ago)

    checker = CommentChecking::OnlyLinkChecker.new(comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot')
    assert_not checker.skip?
    assert checker.check.spam?
  end

  test 'when it is a single internal link by a new user' do
    comment = comments(:script_comment)
    comment.update!(text: 'https://greasyfork.org/')
    comment.poster.update!(created_at: 1.day.ago)

    checker = CommentChecking::OnlyLinkChecker.new(comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot')
    assert_not checker.skip?
    assert_not checker.check.spam?
  end

  test 'when it is a single link by an existing user' do
    comment = comments(:script_comment)
    comment.update!(text: 'https://example.com/')
    comment.poster.update!(created_at: 1.month.ago)

    checker = CommentChecking::OnlyLinkChecker.new(comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot')
    assert checker.skip?
  end

  test 'when it is a multiple links by a new user' do
    comment = comments(:script_comment)
    comment.update!(text: "https://example.com/\nhttps://example.com/\nhttps://example.com/")
    comment.poster.update!(created_at: 1.day.ago)

    checker = CommentChecking::OnlyLinkChecker.new(comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot')
    assert_not checker.skip?
    assert checker.check.spam?
  end

  test 'when it is a link and more text by a new user' do
    comment = comments(:script_comment)
    comment.update!(text: 'visit this site: https://example.com/')
    comment.poster.update!(created_at: 1.day.ago)

    checker = CommentChecking::OnlyLinkChecker.new(comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot')
    assert_not checker.skip?
    assert_not checker.check.spam?
  end

  test 'when it is a href-less <a>' do
    comment = comments(:script_comment)
    comment.update!(text: '<a>test</a>', text_markup: 'html')
    comment.poster.update!(created_at: 1.day.ago)

    checker = CommentChecking::OnlyLinkChecker.new(comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot')
    assert_not checker.skip?
    assert_not checker.check.spam?
  end
end
