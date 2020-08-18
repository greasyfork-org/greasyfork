require 'test_helper'

class AkismetCheckingJobTest < ActiveSupport::TestCase
  test "when it's not spam" do
    discussion = discussions(:non_script_discussion)

    Akismet.expects(:api_key).returns('123')
    Akismet.expects(:check).returns([false, false])

    assert_no_changes -> { Report.count } do
      AkismetCheckingJob.perform_now(discussion, '1.1.1.1', 'User agent', nil)
    end

    discussion.reload

    assert_equal false, discussion.akismet_spam
    assert_equal false, discussion.akismet_blatant
    assert_nil discussion.review_reason
  end

  test 'when it is spam' do
    discussion = discussions(:non_script_discussion)

    Akismet.expects(:api_key).returns('123')
    Akismet.expects(:check).returns([true, false])

    assert_difference -> { Report.count } => 1 do
      AkismetCheckingJob.perform_now(discussion, '1.1.1.1', 'User agent', nil)
    end

    discussion.reload

    assert_equal true, discussion.akismet_spam
    assert_equal false, discussion.akismet_blatant
    assert_equal 'akismet', discussion.review_reason
  end
end
