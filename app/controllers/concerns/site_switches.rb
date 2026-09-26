module SiteSwitches
  extend ActiveSupport::Concern

  included do
    helper_method :greasy?, :sleazy?, :script_subset, :site_name, :greasyfork_host
  end

  def greasy?
    site_code_cache_key == 'greasyfork'
  end

  def sleazy?
    site_code_cache_key == 'sleazyfork'
  end

  def site_name
    sleazy? ? 'Sleazy Fork' : 'Greasy Fork'
  end

  def greasyfork_host
    return 'greasyfork.org' if Rails.env.production?

    'greasyfork.local'
  end

  def script_subset
    return :sleazyfork if sleazy?
    return :greasyfork unless user_signed_in?

    return current_user.show_sensitive ? :all : :greasyfork
  end

  def greasy_only
    render_404 unless greasy?
  end

  def update_host?
    request.subdomain == 'update' || (Rails.env.test? && request.domain == 'localhost')
  end

  def site_cache_key
    return 'greasy' if greasy?
    return 'sleazy' if sleazy?
  end

  def site_code_cache_key
    return 'greasyfork' if Rails.env.test? && request.host == '127.0.0.1'

    case request.domain
    when 'greasyfork.org', 'greasyfork.local' then 'greasyfork'
    when 'sleazyfork.org', 'sleazyfork.local' then 'sleazyfork'
    end
  end
end
