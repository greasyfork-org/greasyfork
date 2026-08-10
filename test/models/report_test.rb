require 'test_helper'

class ReportTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test 'move report on script discussion' do
    discussion = discussions(:script_discussion)
    category = discussion_categories(:greasyfork)
    report = Report.create!(item: discussion, reason: Report::REASON_WRONG_CATEGORY, discussion_category: category, reporter: users(:one))
    report.uphold!(moderator: users(:mod))
    assert_equal category, discussion.reload.discussion_category
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
