module Api
  extend ActiveSupport::Concern

  included do
    before_action :handle_non_api_requests
    skip_before_action :verify_authenticity_token, if: -> { request.format.jsonp? }
  end

  def handle_non_api_requests
    raise ActionController::UnknownFormat if request.subdomain == 'api' && !api_request?
  end

  def handle_api_request
    redirect_to({ subdomain: 'api', format: params[:format] }, allow_other_host: true, status: :permanent_redirect) if request.get? && request.subdomain != 'api' && api_request?
  end

  def api_request?
    request.format.json? || request.format.jsonp? || request.format.atom?
  end
end
