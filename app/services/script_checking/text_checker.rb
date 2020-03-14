module ScriptChecking
  class TextChecker
    class << self
      def check(script_version)
        bst = BlockedScriptText.all.load
        attributes_to_check(script_version).each do |attr|
          bst.each do |b|
            return ScriptChecking::Result.new(ScriptChecking::Result::RESULT_CODE_REVIEW, b.public_reason, b.private_reason, b) if attr.include?(b.text.downcase)
          end
        end
        ScriptChecking::Result.new(ScriptChecking::Result::RESULT_CODE_OK)
      end

      def attributes_to_check(script_version)
        ([script_version.code] + script_version.active_localized_attributes.select { |aa| aa.attribute_key == 'additional_info' }.map(&:attribute_value)).compact.map(&:downcase)
      end
    end
  end
end
