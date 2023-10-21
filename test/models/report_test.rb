require 'test_helper'

class ReportTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def around(&)
    with_sphinx(&)
  end

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
end
