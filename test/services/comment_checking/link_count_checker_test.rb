require 'test_helper'

class LinkCountCheckerTest < ActiveSupport::TestCase
  test 'when it has a lot of links, report' do
    comment_to_check = Comment.create!(discussion: Discussion.last, text: 'https://example.com https://example.com/1 https://example.com/2 https://example.com/3 https://example.com/4 https://example.com/5', poster: users(:one))
    comment_to_check.poster.update!(created_at: 1.day.ago)

    assert CommentChecking::LinkCountChecker.check(comment_to_check, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot').spam?
  end

  test 'when it has few links it is ok' do
    comment_to_check = Comment.create!(discussion: Discussion.last, text: 'https://example.com https://example.com/1', poster: users(:one))
    comment_to_check.poster.update!(created_at: 1.day.ago)

    assert_not CommentChecking::LinkCountChecker.check(comment_to_check, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot').spam?
  end

  test 'when it a lot of internal links, it is ok' do
    comment_to_check = Comment.create!(discussion: Discussion.last, text: 'https://greasyfork.org https://greasyfork.org/1 https://greasyfork.org/2 https://greasyfork.org/3 https://greasyfork.org/4 https://greasyfork.org/5', poster: users(:one))
    comment_to_check.poster.update!(created_at: 1.day.ago)

    assert_not CommentChecking::LinkCountChecker.check(comment_to_check, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot').spam?
  end
end
