module ScriptChecking
  class CodeChecker
    BLOCKED_SCRIPT_CODE_RESULT_TO_CODE = {
      'ban' => ScriptChecking::Result::RESULT_CODE_BAN,
      'block' => ScriptChecking::Result::RESULT_CODE_BLOCK,
      'review' => ScriptChecking::Result::RESULT_CODE_REVIEW,
    }.freeze

    class << self
      def check(script_version)
        code = script_version.code

        results = BlockedScriptCode.all.filter_map do |bc|
          next unless bc.match?(code)
          next if bc.exempt_script?(script_version.script)

          ScriptChecking::Result.new(
            BLOCKED_SCRIPT_CODE_RESULT_TO_CODE[bc.result],
            bc.public_reason,
            bc.private_reason,
            bc,
            notify: bc.notify_admin
          )
        end

        ScriptChecking::Result.highest_result(results)
      end
    end
  end
end
