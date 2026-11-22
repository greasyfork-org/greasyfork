module InspectorErrorRetry
  INSPECTOR_ERROR_MESSAGE = 'Node with given id does not belong to the document'.freeze

  def run
    result = super
    return result if @inspector_retry_attempted || @failures_before_teardown != 1 || result.failures.size != 1

    failure = result.failures.first
    return result unless failure.is_a?(Minitest::UnexpectedError) &&
                         failure.error.is_a?(Selenium::WebDriver::Error::UnknownError) &&
                         failure.error.message.include?('unhandled inspector error') &&
                         failure.error.message.include?(INSPECTOR_ERROR_MESSAGE)

    warn "Retrying #{self.class.name}##{name} after Chrome inspector error: #{INSPECTOR_ERROR_MESSAGE}"
    retry_result = self.class.new(name).run_inspector_retry
    retry_result.failures.unshift(failure) if retry_result.skipped?
    retry_result
  end

  def before_teardown
    @failures_before_teardown = failures.size
    super
  end

  protected

  def run_inspector_retry
    @inspector_retry_attempted = true
    run
  end
end
