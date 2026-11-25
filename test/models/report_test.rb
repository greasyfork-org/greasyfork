require 'test_helper'

class ReportTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test 'reference script must have the same language as the reported script' do
    report = Report.new(
      item: scripts(:style),
      reference_script: scripts(:one),
      reporter: users(:one),
      reason: Report::REASON_UNAUTHORIZED_CODE,
      script_url: 'https://example.com/original.user.css',
      explanation_markup: 'text'
    )

    assert_not report.valid?
    assert_equal ['must be the same language as the reported script'], report.errors[:reference_script]
  end

  test 'reference script with the same language is valid' do
    report = Report.new(
      item: scripts(:style),
      reference_script: scripts(:style_antifeatures),
      reporter: users(:one),
      reason: Report::REASON_UNAUTHORIZED_CODE,
      script_url: 'https://example.com/original.user.css',
      explanation_markup: 'text'
    )

    assert report.valid?, report.errors.full_messages
  end

  test 'move report on script discussion' do
    discussion = discussions(:script_discussion)
    category = discussion_categories(:greasyfork)
    report = Report.create!(item: discussion, reason: Report::REASON_WRONG_CATEGORY, discussion_category: category, reporter: users(:one))
    report.uphold!(moderator: users(:mod))
    assert_equal category, discussion.reload.discussion_category
  end

  test 'duplicate is omitted from manually selectable report reasons' do
    assert_includes Report::SCRIPT_REASONS, Report::REASON_DUPLICATE
    assert_includes Report::DISCUSSION_REASONS, Report::REASON_DUPLICATE
    assert_includes Report::COMMENT_REASONS, Report::REASON_DUPLICATE
    assert_not_includes Report::USER_AND_MESSAGE_REASONS, Report::REASON_DUPLICATE

    comment_report = Report.new(item: comments(:non_script_comment_2), reporter: users(:one))
    script_report = Report.new(item: scripts(:one), reporter: users(:one))
    discussion_report = Report.new(item: discussions(:non_script_discussion), reporter: users(:one))
    user_report = Report.new(item: users(:consumer), reporter: users(:one))
    [comment_report, script_report, discussion_report].each do |report|
      assert_not_includes report.possible_reasons, Report::REASON_DUPLICATE
      assert_includes report.possible_moderator_reasons, Report::REASON_DUPLICATE
    end
    assert_not_includes user_report.possible_reasons, Report::REASON_DUPLICATE
    assert_not_includes user_report.possible_moderator_reasons, Report::REASON_DUPLICATE
  end

  test 'dismiss akismet report on discussion sends notification' do
    discussion = discussions(:script_discussion)
    discussion.update!(review_reason: Discussion::REVIEW_REASON_AKISMET)
    report = Report.create!(item: discussion, reason: Report::REASON_SPAM, reporter: users(:one))
    assert_enqueued_with(job: CommentNotificationJob, args: [discussion.first_comment]) do
      report.dismiss!(moderator: users(:mod), moderator_notes: '')
    end
    assert_nil discussion.reload.review_reason
  end

  test 'dismiss akismet report on comment sends notification' do
    comment = comments(:script_comment)
    comment.update!(review_reason: Discussion::REVIEW_REASON_AKISMET)
    report = Report.create!(item: comment, reason: Report::REASON_SPAM, reporter: users(:one))
    assert_enqueued_with(job: CommentNotificationJob, args: [comment]) do
      report.dismiss!(moderator: users(:mod), moderator_notes: '')
    end
    assert_nil comment.reload.review_reason
  end

  test 'dismissed spam discussion reports send ham feedback for the first comment' do
    discussion = discussions(:script_discussion)
    comment = discussion.first_comment
    submission = AkismetSubmission.create!(item: comment, akismet_params: ['127.0.0.1', 'Bot', { text: comment.text }], result_spam: true, result_blatant: false)
    report = Report.create!(item: discussion, reason: Report::REASON_SPAM, reporter: users(:one))

    assert_enqueued_with(job: AkismetHamJob, args: [submission]) do
      report.dismiss!(moderator: users(:mod), moderator_notes: '')
    end
  end

  test 'human upheld spam report sends feedback for an Akismet miss' do
    discussion = discussions(:script_discussion)
    comment = discussion.first_comment
    submission = AkismetSubmission.create!(item: comment, akismet_params: ['127.0.0.1', 'Bot', { text: comment.text }], result_spam: false, result_blatant: false)
    report = Report.create!(item: discussion, reason: Report::REASON_SPAM, reporter: users(:one))

    assert_enqueued_with(job: AkismetSpamJob, args: [submission]) do
      report.uphold!(moderator: users(:mod))
    end
  end

  test 'automatic decisions and stale submissions are not sent as feedback' do
    comment = comments(:non_script_comment_2)
    AkismetSubmission.create!(item: comment, akismet_params: ['127.0.0.1', 'Bot', { text: comment.text }], result_spam: false, result_blatant: false)
    report = Report.create!(item: comment, reason: Report::REASON_SPAM, auto_reporter: 'rainman')
    assert_no_enqueued_jobs(only: AkismetSpamJob) { report.uphold!(automod: true) }

    comment = comments(:script_comment)
    AkismetSubmission.create!(item: comment, akismet_params: ['127.0.0.1', 'Bot', { text: 'old text' }], result_spam: true, result_blatant: false)
    report = Report.create!(item: comment, reason: Report::REASON_SPAM, reporter: users(:one))
    assert_no_enqueued_jobs(only: AkismetHamJob) { report.dismiss!(moderator: users(:mod), moderator_notes: '') }
  end

  test 'moderator override controls spam feedback' do
    comment = comments(:non_script_comment_2)
    submission = AkismetSubmission.create!(item: comment, akismet_params: ['127.0.0.1', 'Bot', { text: comment.text }], result_spam: false, result_blatant: false)
    report = Report.create!(item: comment, reason: Report::REASON_ABUSE, reporter: users(:one))

    assert_enqueued_with(job: AkismetSpamJob, args: [submission]) do
      report.uphold!(moderator: users(:mod), moderator_reason_override: Report::REASON_SPAM)
    end
  end

  test 'upholding a comment report logs the moderator deletion' do
    comment = comments(:non_script_comment_2)
    report = Report.create!(item: comment, reason: Report::REASON_SPAM, reporter: users(:one))

    assert_difference -> { ModeratorAction.where(comment:).count }, 1 do
      report.uphold!(moderator: users(:mod))
    end

    action = ModeratorAction.find_by!(comment:)
    assert_equal report, action.report
    assert action.action_taken_delete?
  end

  test 'upholding a discussion report logs the moderator deletion' do
    discussion = discussions(:non_script_discussion)
    report = Report.create!(item: discussion, reason: Report::REASON_SPAM, reporter: users(:consumer))

    assert_difference -> { ModeratorAction.where(discussion:).count }, 1 do
      report.uphold!(moderator: users(:mod))
    end

    action = ModeratorAction.find_by!(discussion:)
    assert_equal report, action.report
    assert action.action_taken_delete?
  end

  test 'reporting_blocked_until remains blocked after more than five dismissed reports' do
    user = users(:one)
    6.times { Report.create!(reporter: user, result: Report::RESULT_DISMISSED, item: Script.first, reason: Report::REASON_SPAM) }

    assert_not_nil user.reports_as_reporter.reporting_blocked_until
  end

  test 'reporting_blocked_until only considers the last five resolved reports' do
    user = users(:one)
    5.times { Report.create!(reporter: user, result: Report::RESULT_DISMISSED, item: Script.first, reason: Report::REASON_SPAM) }
    Report.create!(reporter: user, result: Report::RESULT_UPHELD, item: Script.first, reason: Report::REASON_SPAM)

    assert_nil user.reports_as_reporter.reporting_blocked_until
  end

  test 'reporting_blocked_until requires five reports from the last week' do
    user = users(:one)
    Report.create!(reporter: user, result: Report::RESULT_DISMISSED, item: Script.first, reason: Report::REASON_SPAM, created_at: 8.days.ago)
    4.times { Report.create!(reporter: user, result: Report::RESULT_DISMISSED, item: Script.first, reason: Report::REASON_SPAM) }

    assert_nil user.reports_as_reporter.reporting_blocked_until
  end
end
