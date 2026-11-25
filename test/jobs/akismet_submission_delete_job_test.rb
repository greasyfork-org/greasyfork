require 'test_helper'

class AkismetSubmissionDeleteJobTest < ActiveSupport::TestCase
  test 'deletes submissions older than one week' do
    travel_to Time.zone.local(2026, 11, 25, 12) do
      old = submission_for(comments(:non_script_comment_2), created_at: 1.week.ago - 1.second)
      boundary = submission_for(comments(:non_script_comment_2), created_at: 1.week.ago)
      recent = submission_for(comments(:non_script_comment_2), created_at: 1.day.ago)

      AkismetSubmissionDeleteJob.perform_inline

      assert_not AkismetSubmission.exists?(old.id)
      assert AkismetSubmission.exists?(boundary.id)
      assert AkismetSubmission.exists?(recent.id)
    end
  end

  test 'retains submissions for pending reports on their item until resolved' do
    comment = comments(:non_script_comment_2)
    submission = submission_for(comment)
    report = Report.create!(item: comment, reason: Report::REASON_SPAM, reporter: users(:one))

    AkismetSubmissionDeleteJob.perform_inline
    assert AkismetSubmission.exists?(submission.id)

    report.update!(result: Report::RESULT_DISMISSED)
    AkismetSubmissionDeleteJob.perform_inline
    assert_not AkismetSubmission.exists?(submission.id)
  end

  test 'retains first-comment submissions for pending discussion reports but not replies' do
    discussion = discussions(:non_script_discussion)
    first = submission_for(comments(:non_script_comment))
    reply = submission_for(comments(:non_script_comment_2))
    Report.create!(item: discussion, reason: Report::REASON_SPAM, reporter: users(:one))

    AkismetSubmissionDeleteJob.perform_inline

    assert AkismetSubmission.exists?(first.id)
    assert_not AkismetSubmission.exists?(reply.id)
  end

  test 'does not retain a submission for an unrelated report with the same item id' do
    comment = comments(:script_comment)
    submission = submission_for(comment)
    report = Report.create!(item: scripts(:one), reason: Report::REASON_SPAM, reporter: users(:one))
    report.update_columns(item_id: comment.id)

    AkismetSubmissionDeleteJob.perform_inline

    assert_not AkismetSubmission.exists?(submission.id)
  end

  private

  def submission_for(item, created_at: 8.days.ago)
    AkismetSubmission.create!(created_at:, item:, akismet_params: ['a'], result_spam: false, result_blatant: false)
  end
end
