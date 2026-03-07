require 'test_helper'

class SockPuppetCheckerTest < ActiveSupport::TestCase
  def duplicate_comment(comment)
    second_comment = comment.dup
    second_comment.discussion = second_comment.discussion.dup
    second_comment.discussion.save!
    second_comment.save!
    second_comment
  end

  test 'when two users with the same IP post on the same script' do
    comment = comments(:script_comment)
    comment.poster.update!(current_sign_in_ip: '127.0.0.1')

    second_comment = duplicate_comment(comment)
    second_comment_user = User.where.not(id: comment.poster_id).first
    second_comment_user.update!(current_sign_in_ip: '127.0.0.1')
    second_comment.poster = second_comment.discussion.poster = second_comment_user

    checker = CommentChecking::SockPuppetChecker.new(second_comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot')
    assert_not checker.skip?
    assert checker.check.spam?
  end

  test 'when two users with the same IP post on different scripts' do
    comment = comments(:script_comment)
    comment.poster.update!(current_sign_in_ip: '127.0.0.1')

    second_comment = duplicate_comment(comment)
    second_comment_user = User.where.not(id: comment.poster_id).first
    second_comment_user.update!(current_sign_in_ip: '127.0.0.1')
    second_comment.poster = second_comment.discussion.poster = second_comment_user
    second_comment.discussion.script = Script.where.not(id: comment.script.id).first
    second_comment.discussion.save!
    second_comment.save!

    checker = CommentChecking::SockPuppetChecker.new(second_comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot')
    assert_not checker.skip?
    result = checker.check
    assert_not result.spam?, result.text
  end

  test 'when two users with the different IPs post on the same script' do
    comment = comments(:script_comment)
    comment.poster.update!(current_sign_in_ip: '127.0.0.1')

    second_comment = duplicate_comment(comment)
    second_comment_user = User.where.not(id: comment.poster_id).first
    second_comment_user.update!(current_sign_in_ip: '127.0.0.2')
    second_comment.poster = second_comment.discussion.poster = second_comment_user

    checker = CommentChecking::SockPuppetChecker.new(second_comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot')
    assert_not checker.skip?
    result = checker.check
    assert_not result.spam?, result.text
  end

  test 'when two users with the same IP post on the same script separated in time' do
    comment = comments(:script_comment)
    comment.poster.update!(current_sign_in_ip: '127.0.0.1')

    second_comment = duplicate_comment(comment)
    second_comment_user = User.where.not(id: comment.poster_id).first
    second_comment_user.update!(current_sign_in_ip: '127.0.0.1')
    second_comment.poster = second_comment.discussion.poster = second_comment_user
    second_comment.save!

    comment.update!(created_at: 2.days.ago)
    comment.discussion.update!(created_at: 2.days.ago)

    checker = CommentChecking::SockPuppetChecker.new(second_comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot')
    assert_not checker.skip?
    result = checker.check
    assert_not result.spam?, result.text
  end
end
