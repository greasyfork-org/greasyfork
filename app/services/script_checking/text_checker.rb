module ScriptChecking
  class TextChecker
    class << self
      def check(script_version)
        bst = BlockedScriptText.all.load
        results = attributes_to_check(script_version).map do |attr|
          bst.map do |b|
            ScriptChecking::Result.new(b.ban? ? ScriptChecking::Result::RESULT_CODE_BAN : ScriptChecking::Result::RESULT_CODE_REVIEW, b.public_reason, b.private_reason, b) if attr.include?(b.text.downcase)
          end
        end
        results = results.flatten.compact

        ScriptChecking::Result.highest_result(results)
      end

      def attributes_to_check(script_version)
        values = script_version.active_localized_attributes.map(&:attribute_value)
        values += script_version.script.active_localized_attributes.map(&:attribute_value)
        values.compact.map(&:downcase)
      end
    end
  end
end
