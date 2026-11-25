require 'test_helper'

class AkismetSpamJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test 'submits the original checked parameters as spam' do
    params = ['127.0.0.1', 'Bot', { text: 'spam' }]
    submission = AkismetSubmission.create!(item: comments(:script_comment), akismet_params: params, result_spam: false, result_blatant: false)
    Akismet.stubs(:api_key).returns('key')
    Akismet.expects(:spam).with(*params)

    AkismetSpamJob.perform_now(submission)
  end

  test 'queued feedback survives deletion of the submission' do
    comment = comments(:script_comment)
    params = ['127.0.0.1', 'Bot', { text: comment.text }]
    submission = AkismetSubmission.create!(created_at: 8.days.ago, item: comment, akismet_params: params, result_spam: false, result_blatant: false)
    report = Report.create!(item: comment.discussion, reason: Report::REASON_SPAM, reporter: users(:one))
    Akismet.stubs(:api_key).returns('key')
    Akismet.expects(:spam).with(*params)

    report.uphold!(moderator: users(:mod))
    AkismetSubmissionDeleteJob.perform_inline
    assert_not AkismetSubmission.exists?(submission.id)
    perform_enqueued_jobs(only: AkismetSpamJob)
  end
end
