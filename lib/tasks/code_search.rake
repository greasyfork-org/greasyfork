namespace :code_search do
  desc 'reindex'
  task reindex: :environment do
    ScriptCodeSearch.index_all
  end

  desc 'Build the Elasticsearch code search index; subsequent updates require the background job queue'
  task reindex_elasticsearch: :environment do
    ElasticsearchCodeSearch.index_all
  end
end
