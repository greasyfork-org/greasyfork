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
end
