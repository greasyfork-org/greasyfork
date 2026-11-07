class UpdateCheckCountsAggregateJob
  include Sidekiq::Job

  sidekiq_options queue: 'low', lock: :until_executed, on_conflict: :log, lock_ttl: 1.hour.to_i

  BATCH_SIZE = 500

  # Rolls up the rows loaded from the nginx logs (by update_counts_from_log.sh) into per-day counts.
  def perform
    # Anything older than the day of an hour ago has been fully loaded and aggregated.
    cutoff = 1.hour.ago.utc.to_date

    # A plain read with no locks. The join skips deleted scripts, as update_check_counts has a foreign key.
    counts = DailyUpdateCheckCount
             .joins('JOIN scripts ON scripts.id = daily_update_check_counts.script_id')
             .group(:script_id, :update_day)
             .order(:script_id, :update_day)
             .count

    counts.each_slice(BATCH_SIZE) do |slice|
      UpdateCheckCount.upsert_all(slice.map { |(script_id, day), count| { script_id: script_id, update_check_date: day, update_checks: count } })
    end

    DailyUpdateCheckCount.where(update_day: ...cutoff).delete_all
  end
end
