module ScriptChecking
  class CodeChecker
    class << self
      def check(script_version)
        code = script_version.code

        results = BlockedScriptCode.all.filter_map do |bc|
          next unless bc.match?(code)
          next if bc.exempt_script?(script_version.script)

          ScriptChecking::Result.new(
            bc.serious ? ScriptChecking::Result::RESULT_CODE_BAN : ScriptChecking::Result::RESULT_CODE_BLOCK,
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
