class SpammyEmailDomain < ApplicationRecord
  BLOCK_TYPE_CONFIRMATION = 'confirmation'.freeze
  BLOCK_TYPE_SCRIPT = 'block_script'.freeze
  BLOCK_TYPE_REGISTER = 'block_register'.freeze

  BLOCK_TYPE_DESCRIPTIONS = {
    BLOCK_TYPE_CONFIRMATION => 'Script posting delayed',
    BLOCK_TYPE_SCRIPT => "Can't post scripts",
    BLOCK_TYPE_REGISTER => "Can't register",
  }.freeze

  scope :active, -> { where('expires_at IS NULL OR expires_at > NOW()') }

  validates :domain, uniqueness: { case_sensitive: false }

  def blocked_script_posting?
    [BLOCK_TYPE_SCRIPT, BLOCK_TYPE_REGISTER].include?(block_type)
  end

  def description
    BLOCK_TYPE_DESCRIPTIONS[block_type]
  end

  def self.find_active_for_email(email)
    domain = email.split('@').last
    active.find_for_domain(domain)
  end

  def self.find_for_domain(domain)
    find_by(domain: domains_to_match(domain))
  end

  def self.domains_to_match(domain)
    [domain, MatchUri.get_tld_plus_1(domain)].compact.uniq
  end

  def block_type_register?
    block_type == BLOCK_TYPE_REGISTER
  end

  def active?
    expires_at.nil? || expires_at.future?
  end
end
