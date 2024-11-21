require 'rqrcode'

class QrController < ApplicationController
  skip_before_action :set_locale

  def show
    qrcode = RQRCode::QRCode.new(params[:url])
    render body: qrcode.as_svg, content_type: 'image/svg+xml'
  end
end
