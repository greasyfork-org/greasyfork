class MatchURI
  DONT_STRIP_TLD_SITES = ['del.icio.us']
  IP_PATTERN = /^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}):?[0-9]*$/

  def self.get_tld_plus_1(domain)
    return domain if !domain.include?('.')
    return domain if !IP_PATTERN.match(domain).nil?
    return domain if DONT_STRIP_TLD_SITES.include?(domain)
    return domain if !PublicSuffix.valid?(domain)
    pd = PublicSuffix.parse(domain)
    return pd.domain
  end
end