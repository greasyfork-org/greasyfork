class SpammyEmailDomain < ApplicationRecord
  BLOCK_TYPE_CONFIRMATION = 'confirmation'.freeze
  BLOCK_TYPE_SCRIPT = 'block_script'.freeze
  BLOCK_TYPE_REGISTER = 'block_register'.freeze

  BLOCK_TYPE_DESCRIPTIONS = {
    BLOCK_TYPE_CONFIRMATION => 'Script posting delayed',
    BLOCK_TYPE_SCRIPT => "Can't post scripts",
    BLOCK_TYPE_REGISTER => "Can't register",
  }.freeze

  def blocked_script_posting?
    [BLOCK_TYPE_SCRIPT, BLOCK_TYPE_REGISTER].include?(block_type)
  end

  def description
    BLOCK_TYPE_DESCRIPTIONS[block_type]
  end

  def self.find_for_email(email)
    domain = email.split('@').last
    domains = [domain, MatchUri.get_tld_plus_1(domain)].compact.uniq
    find_by(domain: domains)
  end

  def block_type_register?
    block_type == BLOCK_TYPE_REGISTER
  end
end
