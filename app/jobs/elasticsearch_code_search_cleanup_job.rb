class ElasticsearchCodeSearchCleanupJob < ApplicationJob
  queue_as :background

  def perform(index_name)
    ElasticsearchCodeSearch.delete_old_index(index_name)
  end
end
