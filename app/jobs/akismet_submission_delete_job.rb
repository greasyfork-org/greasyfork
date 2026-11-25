class AkismetSubmissionDeleteJob
  include Sidekiq::Job

  sidekiq_options queue: 'background', lock: :until_executed, on_conflict: :log, lock_ttl: 1.hour.to_i

  KEEP_AGE = 1.week

  def perform
    AkismetSubmission
      .where(created_at: ...KEEP_AGE.ago)
      .where(<<~SQL.squish, Discussion.polymorphic_name, Comment.polymorphic_name)
        NOT EXISTS (
          SELECT 1 FROM reports
          WHERE reports.result IS NULL
            AND reports.item_type = akismet_submissions.item_type
            AND reports.item_id = akismet_submissions.item_id
        )
        AND NOT EXISTS (
          SELECT 1 FROM comments
          INNER JOIN reports ON reports.item_type = ? AND reports.item_id = comments.discussion_id
          WHERE akismet_submissions.item_type = ?
            AND comments.id = akismet_submissions.item_id
            AND comments.first_comment = TRUE
            AND reports.result IS NULL
        )
      SQL
      .in_batches.delete_all
  end
end
