require 'test_helper'

class NewUserCheckerTest < ActiveSupport::TestCase
  test 'when it matches' do
    first_discussion, second_discussion = setup_discussions

    assert_not CommentChecking::NewUserChecker.new(first_discussion.comments.first, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot').skip?
    assert_not CommentChecking::NewUserChecker.new(first_discussion.comments.first, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot').check.spam?

    assert_not CommentChecking::NewUserChecker.new(second_discussion.comments.first, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot').skip?
    assert CommentChecking::NewUserChecker.new(second_discussion.comments.first, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot').check.spam?
  end

  test 'skip when not first comment' do
    first_discussion, = setup_discussions
    first_discussion.comments.first.update!(first_comment: false)
    assert CommentChecking::NewUserChecker.new(first_discussion.comments.first, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot').skip?
  end

  test 'skip when script review comment' do
    first_discussion, = setup_discussions
    first_discussion.update!(script_id: Script.first.id, title: nil, discussion_category: discussion_categories(:'script-discussions'), rating: 0)
    assert CommentChecking::NewUserChecker.new(first_discussion.comments.first, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot').skip?
  end

  test 'skip when the user was created long before' do
    first_discussion, = setup_discussions
    first_discussion.poster.update!(created_at: 3.days.ago)
    assert CommentChecking::NewUserChecker.new(first_discussion.comments.first, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot').skip?
  end

  def setup_discussions
    first_discussion = discussions(:non_script_discussion)
    second_discussion = first_discussion.dup
    second_discussion.created_at = first_discussion.created_at + 30.minutes
    second_comment = first_discussion.comments.first.dup
    second_comment.discussion = second_discussion
    second_comment.save!

    first_discussion.poster.update!(created_at: 1.minute.ago)

    [first_discussion, second_discussion]
  end
end
