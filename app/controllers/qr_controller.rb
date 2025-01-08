require 'rqrcode'

class QrController < ApplicationController
  skip_before_action :set_locale

  def show
    unless params[:url]
      head :not_found, content_type: 'text/plain'
      return
    end

    qrcode = RQRCode::QRCode.new(params[:url])
    render body: qrcode.as_svg, content_type: 'image/svg+xml'
  end
end
