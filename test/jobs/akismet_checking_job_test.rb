require 'test_helper'

class AkismetCheckingJobTest < ActiveSupport::TestCase
  test "when it's not spam" do
    discussion = discussions(:non_script_discussion)

    Akismet.expects(:api_key).returns('123')
    Akismet.expects(:check).returns([false, false])

    assert_difference -> { Report.count } => 0, -> { AkismetSubmission.count } => 1 do
      AkismetDiscussionCheckingJob.perform_now(discussion, '1.1.1.1', 'User agent', nil)
    end

    discussion.reload

    assert_nil discussion.review_reason
  end

  test 'when it is spam' do
    discussion = discussions(:non_script_discussion)

    Akismet.expects(:api_key).returns('123')
    Akismet.expects(:check).returns([true, false])

    assert_difference -> { Report.count } => 1, -> { AkismetSubmission.count } => 1 do
      AkismetDiscussionCheckingJob.perform_now(discussion, '1.1.1.1', 'User agent', nil)
    end

    discussion.reload

    assert_equal 'akismet', discussion.review_reason
  end
end
