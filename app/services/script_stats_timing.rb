class ScriptStatsTiming
  def self.measure(step)
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    completed = false
    result = yield
    completed = true
    result
  ensure
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
    logger.info("#{step} status=#{completed ? 'completed' : 'failed'} elapsed=#{format('%.3f', elapsed)}s")
  end

  def self.logger
    @logger ||= Logger.new(Rails.root.join('log/script_stats_refresh.log'))
  end
end
