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
end
