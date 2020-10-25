class ConsecutiveBadRatingsJob < ApplicationJob
  queue_as :low

  def perform
    # Clear out any where that's not the case any more.
    Script.where.not(consecutive_bad_ratings_at: nil).reject(&:consecutive_bad_ratings?).each(&:reset_consecutive_bad_ratings!)

    # Delete those that are old.
    Script.not_deleted.where(['consecutive_bad_ratings_at < ?', Script::CONSECUTIVE_BAD_RATINGS_GRACE_PERIOD.ago]).each do |script|
      script.update(
        script_delete_type_id: ScriptDeleteType::KEEP,
        delete_reason: "Script received #{Script::CONSECUTIVE_BAD_RATINGS_COUNT} bad ratings without an author response.",
        consecutive_bad_ratings_at: nil
      )
    end

    # Find new ones
    # Limit to scripts that have received any discussions for performance reasons.
    Script.not_deleted.where(id: scripts_with_discussions).where(consecutive_bad_ratings_at: nil).find_each do |script|
      if script.consecutive_bad_ratings?
        script.update(consecutive_bad_ratings_at: Time.current)
        ConsecutiveBadRatingsMailer.notify(script).deliver_later
      end
    end

    self.class.set(wait: 1.hour).perform_later unless Rails.env.test?
  end

  def scripts_with_discussions
    Discussion.visible.distinct('script_id').pluck('script_id')
  end
end
