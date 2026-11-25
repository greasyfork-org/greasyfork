require 'test_helper'

class CommentCheckingStatsTest < ActiveSupport::TestCase
  test 'no exceptions' do
    service = CommentCheckingStats.new
    assert_nothing_raised do
      service.overview
    end
  end

  test 'pending and unreviewed results are not treated as confirmed outcomes' do
    comment = comments(:script_comment)
    comment.update!(created_at: Time.current)
    result = CommentCheckResult.create!(comment:, strategy: CommentChecking::CustomChecker.name, result: :spam)
    stats = CommentCheckingStats.new

    assert_includes stats.records(result: :unreviewed), result
    assert_not_includes stats.records(result: :false_positives), result

    report = Report.create!(item: comment.discussion, reason: Report::REASON_SPAM, auto_reporter: 'rainman')
    stats = CommentCheckingStats.new
    assert_includes stats.records(result: :pending), result
    assert_not_includes stats.records(result: :false_positives), result
    assert_not_includes stats.records(result: :unreviewed), result

    report.dismiss!(moderator: users(:mod), moderator_notes: '')
    stats = CommentCheckingStats.new
    assert_includes stats.records(result: :false_positives), result
    assert_not_includes stats.records(result: :pending), result

    comment.update!(edited_at: 1.second.from_now)
    assert_includes CommentCheckingStats.new.records(result: :unreviewed), result
  end

  test 'only human confirmed spam counts as a positive outcome' do
    comment = comments(:non_script_comment_2)
    comment.update!(created_at: Time.current)
    result = CommentCheckResult.create!(comment:, strategy: CommentChecking::CustomChecker.name, result: :ham)
    report = Report.create!(item: comment, reason: Report::REASON_SPAM, auto_reporter: 'rainman')
    report.update!(result: Report::RESULT_UPHELD, automod_resolved: true)
    assert_includes CommentCheckingStats.new.records(result: :unreviewed), result

    report.update!(automod_resolved: false, resolver: users(:mod))
    assert_includes CommentCheckingStats.new.records(result: :false_negatives), result
    assert_includes CommentCheckingStats.new.misses, result
  end

  test 'a report resolved after an edit labels the edited content' do
    comment = comments(:non_script_comment_2)
    comment.update!(created_at: Time.current, edited_at: 1.minute.ago)
    result = CommentCheckResult.create!(comment:, strategy: CommentChecking::CustomChecker.name, result: :ham)
    report = Report.create!(item: comment, reason: Report::REASON_SPAM, reporter: users(:one))
    report.update_columns(updated_at: 2.minutes.ago)

    report.uphold!(moderator: users(:mod))
    assert_includes CommentCheckingStats.new.records(result: :false_negatives), result
  end
end
