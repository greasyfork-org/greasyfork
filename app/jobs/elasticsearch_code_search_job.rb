class ElasticsearchCodeSearchJob < ApplicationJob
  queue_as :background

  def perform(script_id)
    ElasticsearchCodeSearch.index_script(script_id)
  end
end
