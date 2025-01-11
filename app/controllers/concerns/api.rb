module Api
  extend ActiveSupport::Concern

  included do
    before_action :handle_non_api_requests
  end

  def handle_non_api_requests
    raise ActionController::UnknownFormat if request.subdomain == 'api' && !api_request?
  end

  def api_request?
    request.format.json? || request.format.jsonp? || request.format.atom?
  end
end
