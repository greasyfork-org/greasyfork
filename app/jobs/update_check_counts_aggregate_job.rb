class UpdateCheckCountsAggregateJob
  include Sidekiq::Job

  sidekiq_options queue: 'low', lock: :until_executed, on_conflict: :log

  sidekiq_retries_exhausted do |job, _exception|
    SidekiqUniqueJobs::Digests.new.delete_by_digest(job.fetch('lock_digest'))
  end

  BATCH_SIZE = 500

  # Rolls up the rows loaded from the nginx logs (by update_counts_from_log.sh) into per-day counts.
  def perform
    # Imports for the preceding hour are assumed complete before this job runs.
    cutoff = 1.hour.ago.utc.to_date

    # A plain read with no locks. The join skips deleted scripts.
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
