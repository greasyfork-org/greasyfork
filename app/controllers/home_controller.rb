class HomeController < ApplicationController
  include UserTextHelper

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

    # Just using Comment as a container - it could really be anything.
    comment = Comment.new(text: text, text_markup: params[:markup])
    comment.construct_mentions(detect_possible_mentions(comment.text, comment.text_markup))

    render html: format_user_text(comment.text, comment.text_markup, mentions: comment.mentions)
  end

  def search; end
end
