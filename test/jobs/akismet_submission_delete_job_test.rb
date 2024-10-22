require 'test_helper'

class AkismetSubmissionDeleteJobTest < ActiveSupport::TestCase
  test "when it's not old" do
    AkismetSubmission.create!(created_at: Time.zone.now, item: Comment.first, akismet_params: ['a'], result_spam: false, result_blatant: false)

    assert_no_difference -> { AkismetSubmission.count } do
      AkismetSubmissionDeleteJob.perform_inline
    end
  end

  test "when it's old" do
    AkismetSubmission.create!(created_at: 13.months.ago, item: Comment.first, akismet_params: ['a'], result_spam: false, result_blatant: false)

    assert_difference -> { AkismetSubmission.count } => -1 do
      AkismetSubmissionDeleteJob.perform_inline
    end
  end
end
