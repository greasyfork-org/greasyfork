module UserIndexing
  extend ActiveSupport::Concern

  SCRIPT_STAT_MAPPINGS = [:all, :greasyfork, :sleazyfork].map do |subset|
    {
      "#{subset}_script_count" => {
        type: 'integer',
      },
      "#{subset}_script_daily_installs" => {
        type: 'integer',
      },
      "#{subset}_script_total_installs" => {
        type: 'integer',
      },
      "#{subset}_script_ratings" => {
        type: 'integer',
      },
      "#{subset}_script_last_created" => {
        type: 'date',
      },
      "#{subset}_script_last_updated" => {
        type: 'date',
      },
    }
  end.reduce({}, :merge)

  included do
    searchkick callbacks: false,
               max_result_window: 10_000, # Refuse to load past this, as ES raises an error anyway
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
                   created_at: {
                     type: 'date',
                   },
                   banned: {
                     type: 'boolean',
                   },
                   **SCRIPT_STAT_MAPPINGS,
                 },
               }

    after_commit if: ->(model) { model.previous_changes.keys.intersect?(%w[name created_at banned_at email_domain ip]) } do
      reindex(mode: :async) if Searchkick.callbacks?
    end
  end

  def search_data
    {
      name:,
      created_at:,
      banned: banned?,
      email_domain:,
      ip: current_sign_in_ip,
      **calculate_stats,
    }
  end
end
