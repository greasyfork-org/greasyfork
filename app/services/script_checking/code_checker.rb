module ScriptChecking
  class CodeChecker
    class << self
      def check(script_version)
        code = script_version.code

        results = BlockedScriptCode.all.filter_map do |bc|
          next unless bc.match?(code)
          next unless bc.originating_script_id.nil? || (bc.originating_script.authors.map(&:user_id) & script_version.script.authors.map(&:user_id)).none?

          ScriptChecking::Result.new(
            bc.serious ? ScriptChecking::Result::RESULT_CODE_BAN : ScriptChecking::Result::RESULT_CODE_BLOCK,
            bc.public_reason,
            bc.private_reason,
            bc
          )
        end

        ScriptChecking::Result.highest_result(results)
      end
    end
  end
end
