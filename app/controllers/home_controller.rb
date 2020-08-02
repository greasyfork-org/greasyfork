class HomeController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:sso, :routing_error]

  def index
    @ad_method = choose_ad_method
  end

  def preview_markup
    if params[:url] == 'true'
      begin
        text = ScriptImporter::BaseScriptImporter.download(params[:text])
        absolute_text = ScriptImporter::BaseScriptImporter.absolutize_references(text, params[:text])
        text = absolute_text unless absolute_text.nil?
      rescue ArgumentError => e
        @text = e
        render 'home/error'
        return
      end
    else
      text = params[:text]
    end
    render html: view_context.format_user_text(text, params[:markup])
  end

  def search; end
end
