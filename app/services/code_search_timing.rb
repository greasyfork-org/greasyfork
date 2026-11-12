class CodeSearchTiming
  def self.measure(backend)
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    completed = false
    result = yield
    completed = true
    result
  ensure
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
    Rails.logger.info("#{backend} code search status=#{completed ? 'completed' : 'failed'} elapsed=#{format('%.3f', elapsed)}s")
  end
end
