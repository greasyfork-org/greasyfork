class License < ApplicationRecord
  def explanation_url
    summary_url || self.class.tldr_search_url(code)
  end

  def self.tldr_search_url(text)
    "https://tldrlegal.com/search?query=#{URI.encode_www_form_component(text)}"
  end
end
