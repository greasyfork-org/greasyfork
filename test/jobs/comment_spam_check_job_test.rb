require 'test_helper'

class CommentSpamCheckJobTest < ActiveSupport::TestCase
  test "when it's not spam" do
    comment = comments(:script_comment)

    Akismet.expects(:api_key).returns('123')
    Akismet.expects(:check).returns([false, false])

    assert_difference -> { Report.count } => 0, -> { AkismetSubmission.count } => 1 do
      CommentSpamCheckJob.perform_now(comment, '1.1.1.1', 'User agent', nil)
    end
  end

  test 'when it is akismet spam' do
    comment = comments(:script_comment)

    Akismet.expects(:api_key).returns('123')
    Akismet.expects(:check).returns([true, false])

    assert_difference -> { Report.count } => 1, -> { AkismetSubmission.count } => 1 do
      CommentSpamCheckJob.perform_now(comment, '1.1.1.1', 'User agent', nil)
    end

    assert_equal Discussion::REVIEW_REASON_AKISMET, comment.reload.review_reason
  end

  test 'when it is repeated comment spam from new users' do
    comment = comments(:script_comment)
    comment.poster.update(created_at: Time.zone.now)
    comment.update!(text: 'totally unique content')
    second_comment = comment.dup
    second_comment.save!

    Akismet.stubs(:api_key).returns('123')
    Akismet.stubs(:check).returns([false, false])

    assert_no_difference -> { Report.count } do
      CommentSpamCheckJob.perform_now(comment, '1.1.1.1', 'User agent', nil)
    end

    assert_difference -> { Report.count } => 1 do
      CommentSpamCheckJob.perform_now(second_comment, '1.1.1.1', 'User agent', nil)
    end
  end

  test 'when it is a repeated comment spam from an old user' do
    comment = comments(:script_comment)
    comment.poster.update(created_at: 1.month.ago)
    comment.update!(text: 'totally unique content')
    second_comment = comment.dup
    second_comment.save!

    Akismet.stubs(:api_key).returns('123')
    Akismet.stubs(:check).returns([false, false])

    assert_no_difference -> { Report.count } do
      CommentSpamCheckJob.perform_now(comment, '1.1.1.1', 'User agent', nil)
    end

    assert_no_difference -> { Report.count } do
      CommentSpamCheckJob.perform_now(second_comment, '1.1.1.1', 'User agent', nil)
    end
  end

  test 'when it is a repost by a new user of a recently deleted comment' do
    comment = comments(:script_comment)
    comment.update!(text: 'totally unique content')
    second_comment = comment.dup
    second_comment.poster = users(:one)
    second_comment.poster.update!(created_at: 1.day.ago)
    second_comment.save!
    comment.update(deleted_at: Time.zone.now)

    Akismet.stubs(:api_key).returns('123')
    Akismet.stubs(:check).returns([false, false])

    assert_difference -> { Report.count } => 1 do
      CommentSpamCheckJob.perform_now(second_comment, '1.1.1.1', 'User agent', nil)
    end
  end

  test 'when it is a repost by a new user of a non-deleted comment' do
    comment = comments(:script_comment)
    comment.update!(text: 'totally unique content')
    second_comment = comment.dup
    second_comment.poster = users(:one)
    second_comment.poster.update!(created_at: 1.day.ago)
    second_comment.save!

    Akismet.stubs(:api_key).returns('123')
    Akismet.stubs(:check).returns([false, false])

    assert_no_difference -> { Report.count } do
      CommentSpamCheckJob.perform_now(second_comment, '1.1.1.1', 'User agent', nil)
    end
  end

  test 'when it is repeated link spam from new users' do
    comment = comments(:script_comment)
    comment.poster.update(created_at: Time.zone.now)
    comment.update!(text: 'totally unique content with a link: https://example.com')
    second_comment = comment.dup
    second_comment.text = 'some other content with the same link: https://example.com'
    second_comment.save!

    Akismet.stubs(:api_key).returns('123')
    Akismet.stubs(:check).returns([false, false])

    assert_no_difference -> { Report.count } do
      CommentSpamCheckJob.perform_now(comment, '1.1.1.1', 'User agent', nil)
    end

    assert_difference -> { Report.count } => 1 do
      CommentSpamCheckJob.perform_now(second_comment, '1.1.1.1', 'User agent', nil)
    end
  end

  test 'when it is repeated link spam from an old user' do
    comment = comments(:script_comment)
    comment.poster.update(created_at: 1.month.ago)
    comment.update!(text: 'totally unique content with a link: https://example.com')
    second_comment = comment.dup
    second_comment.text = 'some other content with the same link: https://example.com'
    second_comment = comment.dup
    second_comment.save!

    Akismet.stubs(:api_key).returns('123')
    Akismet.stubs(:check).returns([false, false])

    assert_no_difference -> { Report.count } do
      CommentSpamCheckJob.perform_now(comment, '1.1.1.1', 'User agent', nil)
    end

    assert_no_difference -> { Report.count } do
      CommentSpamCheckJob.perform_now(second_comment, '1.1.1.1', 'User agent', nil)
    end
  end

  test 'when it is a link repost by a new user of a recently deleted comment' do
    comment = comments(:script_comment)
    comment.update!(text: 'totally unique content with a link: https://example.com')
    second_comment = comment.dup
    second_comment.text = 'some other content with the same link: https://example.com'
    second_comment.poster = users(:one)
    second_comment.poster.update!(created_at: 1.day.ago)
    second_comment.save!
    comment.update(deleted_at: Time.zone.now)

    Akismet.stubs(:api_key).returns('123')
    Akismet.stubs(:check).returns([false, false])

    assert_difference -> { Report.count } => 1 do
      CommentSpamCheckJob.perform_now(second_comment, '1.1.1.1', 'User agent', nil)
    end
  end

  test 'when it is a link repost by a new user of a non-deleted comment' do
    comment = comments(:script_comment)
    comment.update!(text: 'totally unique content with a link: https://example.com')
    second_comment = comment.dup
    second_comment.text = 'some other content with the same link: https://example.com'
    second_comment.poster = users(:one)
    second_comment.poster.update!(created_at: 1.day.ago)
    second_comment.save!

    Akismet.stubs(:api_key).returns('123')
    Akismet.stubs(:check).returns([false, false])

    assert_no_difference -> { Report.count } do
      CommentSpamCheckJob.perform_now(second_comment, '1.1.1.1', 'User agent', nil)
    end
  end

  test 'when it is a link repost by a new user of a multiple recently deleted comments, the report is auto-upheld' do
    comment = comments(:script_comment)
    comment.update!(text: 'totally unique content with a link: https://example.com')
    second_comment = comment.dup
    second_comment.save!

    comment_to_check = comment.dup
    comment_to_check.text = 'some other content with the same link: https://example.com'
    comment_to_check.poster = users(:one)
    comment_to_check.poster.update!(created_at: 1.day.ago)
    comment_to_check.save!

    comment.update(deleted_at: 1.day.ago)
    second_comment.update(deleted_at: 1.day.ago)

    Akismet.stubs(:api_key).returns('123')
    Akismet.stubs(:check).returns([false, false])

    assert_difference -> { Report.count } => 1 do
      CommentSpamCheckJob.perform_now(comment_to_check, '1.1.1.1', 'User agent', nil)
    end

    assert Report.last.upheld?
    assert comment_to_check.poster.banned?
  end
end
