module UserIndexing
  extend ActiveSupport::Concern

  included do
    searchkick callbacks: :async,
               searchable: [:name],
               filterable: [:created_at, :script_count, :banned, :script_daily_installs, :script_total_installs, :script_last_created, :script_last_updated, :script_ratings, :email_domain, :ip],
               # Match anywhere in the word, not just the full word.
               word_middle: [:name],
               # Apply additional mappings for the name field - type: keyword to make it sortable, and define case
               # insensitive sort.
               settings: {
                 analysis: {
                   normalizer: {
                     case_insensitive_sort: {
                       type: 'custom',
                       char_filter: [],
                       filter: %w[lowercase asciifolding],
                     },
                   },
                 },
               },
               merge_mappings: true,
               mappings: { properties: { name: { type: 'keyword', normalizer: 'case_insensitive_sort' } } }
  end

  def search_data
    {
      name:,
      created_at:,
      script_count: stats_script_count,
      banned: banned?,
      script_daily_installs: stats_script_daily_installs,
      script_total_installs: stats_script_total_installs,
      script_last_created: stats_script_last_created,
      script_last_updated: stats_script_last_updated,
      script_ratings: stats_script_ratings,
      email_domain:,
      ip: current_sign_in_ip,
    }
  end
end
