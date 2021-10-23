class PingRequestCheckingService
  STRATEGIES = [
    PingRequestChecking::Locale,
    PingRequestChecking::UserAgent,
    PingRequestChecking::Params,
    PingRequestChecking::SessionInstallKey,
  ].freeze

  def self.check(request)
    STRATEGIES.select { |s| s.check(request) }.map(&:to_s)
  end
end
