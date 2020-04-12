class SpammyEmailDomain < ApplicationRecord
  BLOCK_TYPE_CONFIRMATION = 'confirmation'
  BLOCK_TYPE_SCRIPT = 'block_script'
  BLOCK_TYPE_REGISTER = 'block_register'

  def blocked_script_posting?
    [BLOCK_TYPE_SCRIPT, BLOCK_TYPE_REGISTER].include?(block_type)
  end

  def description
    case block_type
    when BLOCK_TYPE_CONFIRMATION; 'Script posting delayed'
    when BLOCK_TYPE_SCRIPT; "Can't post scripts"
    when BLOCK_TYPE_REGISTER; "Can't register"
    end
  end
end
