class BlockedScriptText < ApplicationRecord
  RESULT_CODE_REVIEW = 'review'.freeze
  RESULT_CODE_BAN = 'ban'.freeze

  scope :bannable, -> { where(result: RESULT_CODE_BAN) }

  def review?
    result == RESULT_CODE_REVIEW
  end

  def ban?
    result == RESULT_CODE_BAN
  end
end
