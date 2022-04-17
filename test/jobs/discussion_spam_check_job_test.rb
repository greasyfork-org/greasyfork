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
    discussion = discussions(:non_script_discussion)
    discussion.first_comment.update(text: '网12345567890')

    assert_difference -> { Report.count } => 1, -> { AkismetSubmission.count } => 0 do
      DiscussionSpamCheckJob.perform_now(discussion, '1.1.1.1', 'User agent', nil)
    end

    discussion.reload

    assert_equal Discussion::REVIEW_REASON_RAINMAN, discussion.review_reason
  end
end
