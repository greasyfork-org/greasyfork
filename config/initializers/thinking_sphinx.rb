ThinkingSphinx::Connection.persistent = false

# To disambiguate #search (ES vs TS).
module DisambiguousThinkingSphinx
  extend ActiveSupport::Concern

  module ClassMethods
    def ts_search(query = nil, options = {})
      merge_search ThinkingSphinx.search, query, options
    end
  end
end
ActiveSupport.on_load(:active_record) { include DisambiguousThinkingSphinx }
