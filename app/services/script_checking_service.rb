class ScriptCheckingService
  STRATEGIES = [
    ScriptChecking::LinkChecker,
    ScriptChecking::CodeChecker,
    ScriptChecking::TextChecker,
  ].freeze

  def self.check(script_version)
    results = STRATEGIES.map { |s| s.check(script_version) }
    [ScriptChecking::Result::RESULT_CODE_BAN, ScriptChecking::Result::RESULT_CODE_BLOCK, ScriptChecking::Result::RESULT_CODE_REVIEW, ScriptChecking::Result::RESULT_CODE_OK].each do |result_code|
      rv = results.select { |result| result.code == result_code }
      return [rv, result_code] if rv.any?
    end
  end
end
