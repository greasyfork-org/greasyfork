module UserIndexing
  extend ActiveSupport::Concern

  included do
    searchkick callbacks: false,
               searchable: [:name],
               # All non-string fields are always filterable; we want to limit which string fields are filterable.
               filterable: [:ip, :email_domain],
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
               mappings: {
                 properties: {
                   name: {
                     type: 'keyword',
                     normalizer: 'case_insensitive_sort',
                   },
                   script_count: {
                     type: 'integer',
                   },
                   script_daily_installs: {
                     type: 'integer',
                   },
                   script_total_installs: {
                     type: 'integer',
                   },
                   script_ratings: {
                     type: 'integer',
                   },
                   created_at: {
                     type: 'date',
                   },
                   script_last_created: {
                     type: 'date',
                   },
                   script_last_updated: {
                     type: 'date',
                   },
                   banned: {
                     type: 'boolean',
                   },
                 },
               }

    after_commit if: ->(model) { model.previous_changes.keys.intersect?(%w[name created_at script_count banned stats_script_daily_installs script_total_installs script_last_created script_last_updated script_ratings email_domain ip]) } do
      reindex(mode: :async) if Searchkick.callbacks?
    end
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
