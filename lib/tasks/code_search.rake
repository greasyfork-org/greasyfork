namespace :code_search do
  desc 'reindex'
  task reindex: :environment do
    ScriptCodeSearch.index_all
  end
end
