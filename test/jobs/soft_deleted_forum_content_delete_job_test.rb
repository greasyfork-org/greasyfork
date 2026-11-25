require 'test_helper'

class SoftDeletedForumContentDeleteJobTest < ActiveSupport::TestCase
  test 'permanently deletes old soft-deleted discussions and their comments' do
    travel_to Time.zone.local(2026, 11, 25, 12) do
      discussion = discussions(:non_script_discussion)
      comment_ids = discussion.comments.pluck(:id)
      report = Report.create!(item: discussion, reason: Report::REASON_SPAM, reporter: users(:geoff))
      discussion.soft_destroy!
      discussion.update_columns(deleted_at: 1.year.ago - 1.second)
      discussion.comments.update_all(deleted_at: 1.year.ago - 1.second)

      SoftDeletedForumContentDeleteJob.perform_inline

      assert_not Discussion.exists?(discussion.id)
      assert_not Comment.exists?(id: comment_ids)
      assert_not Report.exists?(report.id)
    end
  end

  test 'deletes old soft-deleted comments but keeps newer and active content' do
    travel_to Time.zone.local(2026, 11, 25, 12) do
      discussion = discussions(:non_script_discussion)
      first_comment = comments(:non_script_comment)
      old_comment = comments(:non_script_comment_2)
      recent_comment = discussion.comments.create!(poster: users(:geoff), text: 'Recent', text_markup: 'html')
      boundary_comment = discussion.comments.create!(poster: users(:geoff), text: 'Boundary', text_markup: 'html')
      old_comment.soft_destroy!
      recent_comment.soft_destroy!
      boundary_comment.soft_destroy!
      old_comment.update_columns(deleted_at: 1.year.ago - 1.second)
      boundary_comment.update_columns(deleted_at: 1.year.ago)
      first_comment.update_columns(created_at: 2.years.ago)
      discussion.update_columns(created_at: 2.years.ago)
      report = Report.create!(item: old_comment, reason: Report::REASON_SPAM, reporter: users(:one))

      SoftDeletedForumContentDeleteJob.perform_inline

      assert_not Comment.exists?(old_comment.id)
      assert_not Report.exists?(report.id)
      assert Comment.exists?(recent_comment.id)
      assert Comment.exists?(boundary_comment.id)
      assert Comment.exists?(first_comment.id)
      assert Discussion.exists?(discussion.id)
    end
  end

  test 'does not delete a newer discussion when its first comment is older than the cutoff' do
    travel_to Time.zone.local(2026, 11, 25, 12) do
      first_comment = comments(:non_script_comment)
      discussion = first_comment.discussion
      first_comment.soft_destroy!
      first_comment.update_columns(deleted_at: 1.year.ago - 1.second)
      discussion.update_columns(deleted_at: 1.year.ago)

      SoftDeletedForumContentDeleteJob.perform_inline
      assert Discussion.exists?(discussion.id)
      assert Comment.exists?(first_comment.id)

      travel 1.second
      SoftDeletedForumContentDeleteJob.perform_inline
      assert_not Discussion.exists?(discussion.id)
      assert_not Comment.exists?(first_comment.id)
    end
  end
end
