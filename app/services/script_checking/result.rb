module ScriptChecking
  class Result
    RESULT_CODE_OK = :ok
    RESULT_CODE_BLOCK = :block
    RESULT_CODE_REVIEW = :review
    RESULT_CODE_BAN = :ban

    attr_accessor :code, :public_reason, :private_reason, :related_object

    def initialize(code, public_reason = nil, private_reason = nil, related_object = nil)
      @code = code
      @public_reason = public_reason
      @private_reason = private_reason
      @related_object = related_object
    end

    def as_json(_options = {})
      {
        code: code,
        public_reason: public_reason,
        private_reason: private_reason,
        related_object_id: related_object&.id,
        related_object_class: related_object&.class&.name,
      }
    end

    def self.highest_result(results)
      results.find { |r| r.code == ScriptChecking::Result::RESULT_CODE_BAN } || results.first || ScriptChecking::Result.new(ScriptChecking::Result::RESULT_CODE_OK)
    end
  end
end
