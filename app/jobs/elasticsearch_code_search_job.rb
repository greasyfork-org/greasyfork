class ElasticsearchCodeSearchJob < ApplicationJob
  queue_as :background

  retry_on ElasticsearchCodeSearch::AlreadyRunningError, wait: 5.minutes, attempts: :unlimited

  def perform(script_id)
    ElasticsearchCodeSearch.index_script(script_id)
  end
end
