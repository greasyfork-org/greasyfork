module ScriptIndexing
  extend ActiveSupport::Concern

  included do
    searchkick callbacks: false,
               max_result_window: 10_000, # Refuse to load past this, as ES raises an error anyway
               searchable: [:name, :description, :additional_info, :author],
               filterable: [],
               # Match anywhere in the word, not just the full word.
               word_middle: [:name, :description, :additional_info, :author],
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
                   description: {
                     type: 'keyword',
                   },
                   additional_info: {
                     type: 'keyword',
                     ignore_above: 10_000,
                   },
                   author: {
                     type: 'keyword',
                   },
                   author_ids: {
                     type: 'integer',
                   },
                   created_at: {
                     type: 'date',
                   },
                   code_updated_at: {
                     type: 'date',
                   },
                   total_installs: {
                     type: 'integer',
                   },
                   daily_installs: {
                     type: 'integer',
                   },
                   sensitive: {
                     type: 'boolean',
                   },
                   script_type: {
                     type: 'integer',
                   },
                   fan_score: {
                     type: 'float',
                   },
                   site_application_id: {
                     type: 'integer',
                   },
                   locale_id: {
                     type: 'integer',
                   },
                   available_as_js: {
                     type: 'boolean',
                   },
                   available_as_css: {
                     type: 'boolean',
                   },
                 },
               }

    scope :search_import, -> { includes(:localized_attributes, :users, :script_applies_tos) }
    scope :indexable, -> { not_deleted.where.not(script_type: :unlisted).where.not(review_state: 'required') }

    after_commit if: ->(model) { should_index? && model.previous_changes.keys.intersect?(%w[created_at code_updated_at total_installs daily_installs sensitive script_type fan_score available_as_js available_as_css]) } do
      reindex(mode: :async) if Searchkick.callbacks?
    end

    after_commit if: ->(model) { model.previous_changes.keys.intersect?(%w[deleted_at script_type delete_type]) } do
      reindex(mode: :async) if Searchkick.callbacks?
    end

    # Because these change the authors' "script author" and "number of scripts" stats
    after_create_commit :reindex_authors
    after_destroy_commit :reindex_authors
    after_update_commit :reindex_authors, if: ->(model) { model.previous_changes.keys.intersect?(%w[deleted_at script_type]) }
  end

  def search_data
    {
      name: search_value_from_localized_attributes('name'),
      description: search_value_from_localized_attributes('description'),
      additional_info: search_value_from_localized_attributes('additional_info'),
      author: users.map(&:name).join(' '),
      author_ids: users.map(&:id),
      created_at:,
      code_updated_at:,
      total_installs:,
      daily_installs:,
      sensitive:,
      script_type: Script.script_types[script_type],
      fan_score:,
      site_application_id: script_applies_tos.map(&:site_application_id),
      locale: localized_attributes.map(&:locale_id).uniq,
      available_as_js: js? || css_convertible_to_js,
      available_as_css: css?,
    }
  end

  def search_value_from_localized_attributes(key)
    values = localized_attributes.select { |la| la.attribute_key == key }
    if key == 'additional_info'
      values.map! { |v| ApplicationController.helpers.format_user_text_as_plain(v.attribute_value, v.value_markup) }
    else
      values.map!(&:attribute_value)
    end
    values.join(' ').truncate_bytes(32_766, omission: nil)
  end

  def should_index?
    !unlisted? && !deleted? && !review_required?
  end

  def reindex_authors
    users.each { |u| u.reindex(mode: :async) } if Searchkick.callbacks?
  end
end
