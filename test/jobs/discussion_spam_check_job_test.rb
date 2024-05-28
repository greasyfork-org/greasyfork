require 'test_helper'

class DiscussionSpamCheckJobTest < ActiveSupport::TestCase
  test "when it's not spam" do
    discussion = discussions(:non_script_discussion)

    Akismet.expects(:api_key).returns('123')
    Akismet.expects(:check).returns([false, false])

    assert_difference -> { Report.count } => 0, -> { AkismetSubmission.count } => 1 do
      DiscussionSpamCheckJob.perform_now(discussion, '1.1.1.1', 'User agent', nil)
    end

    discussion.reload

    assert_nil discussion.review_reason
  end

  test 'when it is akismet spam' do
    discussion = discussions(:non_script_discussion)

    Akismet.expects(:api_key).returns('123')
    Akismet.expects(:check).returns([true, false])

    assert_difference -> { Report.count } => 1, -> { AkismetSubmission.count } => 1 do
      DiscussionSpamCheckJob.perform_now(discussion, '1.1.1.1', 'User agent', nil)
    end

    discussion.reload

    assert_equal Discussion::REVIEW_REASON_AKISMET, discussion.review_reason
  end

  test 'when it is pattern spam' do
    skip 'Pattern check disabled'
    discussion = discussions(:non_script_discussion)
    discussion.first_comment.update(text: '网12345567890')

    assert_difference -> { Report.count } => 1, -> { AkismetSubmission.count } => 0 do
      DiscussionSpamCheckJob.perform_now(discussion, '1.1.1.1', 'User agent', nil)
    end

    discussion.reload

    assert_equal Discussion::REVIEW_REASON_RAINMAN, discussion.review_reason
  end

  test 'when it is repeated comment spam from new users' do
    comment = comments(:script_comment)
    comment.poster.update(created_at: Time.zone.now)
    comment.update!(text: 'totally unique content')
    second_comment = comment.dup
    second_comment.discussion = comment.discussion.dup
    second_comment.save!

    Akismet.stubs(:api_key).returns('123')
    Akismet.stubs(:check).returns([false, false])

    assert_no_difference -> { Report.count } do
      DiscussionSpamCheckJob.perform_now(comment.discussion, '1.1.1.1', 'User agent', nil)
    end

    assert_difference -> { Report.count } => 1 do
      DiscussionSpamCheckJob.perform_now(second_comment.discussion, '1.1.1.1', 'User agent', nil)
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
      DiscussionSpamCheckJob.perform_now(comment.discussion, '1.1.1.1', 'User agent', nil)
    end

    assert_no_difference -> { Report.count } do
      DiscussionSpamCheckJob.perform_now(second_comment.discussion, '1.1.1.1', 'User agent', nil)
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
      DiscussionSpamCheckJob.perform_now(second_comment.discussion, '1.1.1.1', 'User agent', nil)
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
      DiscussionSpamCheckJob.perform_now(second_comment.discussion, '1.1.1.1', 'User agent', nil)
    end
  end

  test 'when it is repeated link spam from new users' do
    comment = comments(:script_comment)
    comment.poster.update(created_at: Time.zone.now)
    comment.update!(text: 'totally unique content with a link: https://example.com')
    second_comment = comment.dup
    second_comment.discussion = comment.discussion.dup
    second_comment.text = 'some other content with the same link: https://example.com'
    second_comment.save!

    Akismet.stubs(:api_key).returns('123')
    Akismet.stubs(:check).returns([false, false])

    assert_no_difference -> { Report.count } do
      DiscussionSpamCheckJob.perform_now(comment.discussion, '1.1.1.1', 'User agent', nil)
    end

    assert_difference -> { Report.count } => 1 do
      DiscussionSpamCheckJob.perform_now(second_comment.discussion, '1.1.1.1', 'User agent', nil)
    end
  end

  test 'when it is repeated link spam from an old user' do
    comment = comments(:script_comment)
    comment.poster.update(created_at: 1.month.ago)
    comment.update!(text: 'totally unique content with a link: https://example.com')
    second_comment = comment.dup
    second_comment.text = 'some other content with the same link: https://example.com'
    second_comment.save!

    Akismet.stubs(:api_key).returns('123')
    Akismet.stubs(:check).returns([false, false])

    assert_no_difference -> { Report.count } do
      DiscussionSpamCheckJob.perform_now(comment.discussion, '1.1.1.1', 'User agent', nil)
    end

    assert_no_difference -> { Report.count } do
      DiscussionSpamCheckJob.perform_now(second_comment.discussion, '1.1.1.1', 'User agent', nil)
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
      DiscussionSpamCheckJob.perform_now(second_comment.discussion, '1.1.1.1', 'User agent', nil)
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
      DiscussionSpamCheckJob.perform_now(second_comment.discussion, '1.1.1.1', 'User agent', nil)
    end
  end
end
