class ScriptStatsRefreshJob
  include Sidekiq::Job

  sidekiq_options queue: 'low', lock: :until_executed, on_conflict: :log

  sidekiq_retries_exhausted do |job, _exception|
    SidekiqUniqueJobs::Digests.new.delete_by_digest(job.fetch('lock_digest'))
  end

  def perform
    progress = ScriptStatsRefreshProgress.find_or_create_by!(id: 1)

    if progress.next_step == 'fan'
      UpdateFanCountsJob.new.perform
      progress.update!(next_step: 'install')
    end

    if progress.next_step == 'install'
      UpdateInstallCountsJob.new.perform
      progress.update!(next_step: 'user')
    end

    raise "Unknown script stats refresh step: #{progress.next_step}" unless progress.next_step == 'user'

    UserStatsRefreshJob.new.perform
    progress.update!(next_step: 'fan')
  end
end
