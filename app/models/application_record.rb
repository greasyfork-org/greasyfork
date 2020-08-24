class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def slugify(name)
    return name if name.nil?

    # take out swears
    r = name.downcase.gsub(/motherfucking|motherfucker|fucking|fucker|fucks|fuck|shitty|shits|shit|niggers|nigger|cunts|cunt/, '')
    # multiple non-alphas into one
    r.gsub!(/([^[:alnum:]])[^[:alnum:]]+/) { |_s| Regexp.last_match(1) }
    # leading non-alphas
    r.gsub!(/^[^[:alnum:]]+/, '')
    # trailing non-alphas
    r.gsub!(/[^[:alnum:]]+$/, '')
    # non-alphas into dashes
    r.gsub!(/[^[:alnum:]]/, '-')
    r
  end
end
