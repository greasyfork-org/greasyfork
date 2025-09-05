class MatchUri
  DONT_STRIP_TLD_SITES = ['del.icio.us'].freeze
  IP_PATTERN = /^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}):?[0-9]*$/

  def self.get_tld_plus_1(domain)
    return domain if unparseable?(domain)

    PublicSuffix.parse(domain).domain
  end

  def self.get_sld(domain)
    return domain if unparseable?(domain)

    PublicSuffix.parse(domain).sld
  end

  def self.unparseable?(domain)
    return true unless domain.include?('.')
    return true unless IP_PATTERN.match(domain).nil?
    return true if DONT_STRIP_TLD_SITES.include?(domain)
    return true unless PublicSuffix.valid?(domain)

    false
  end
end
