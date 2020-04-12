class SpammyEmailDomain < ApplicationRecord
  BLOCK_TYPE_CONFIRMATION = 'confirmation'.freeze
  BLOCK_TYPE_SCRIPT = 'block_script'.freeze
  BLOCK_TYPE_REGISTER = 'block_register'.freeze

  def blocked_script_posting?
    [BLOCK_TYPE_SCRIPT, BLOCK_TYPE_REGISTER].include?(block_type)
  end

  def description
    case block_type
    when BLOCK_TYPE_CONFIRMATION then 'Script posting delayed'
    when BLOCK_TYPE_SCRIPT then "Can't post scripts"
    when BLOCK_TYPE_REGISTER then "Can't register"
    end
  end
end
