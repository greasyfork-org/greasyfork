module ScriptIndexing
  extend ActiveSupport::Concern

  included do
    searchkick callbacks: :async,
               filterable: [:created_at, :code_updated_at, :total_installs, :daily_installs, :sensitive, :script_type, :fan_score, :site_application_id, :locale, :available_as_js, :available_as_css]

    scope :search_import, -> { includes(:localized_attributes, :users, :script_applies_tos) }
  end

  def search_data
    {
      name: search_value_from_localized_attributes('name'),
      description: search_value_from_localized_attributes('description'),
      additional_info: search_value_from_localized_attributes('additional_info'),
      author: users.map(&:name).join(' '),
      created_at: created_at,
      code_updated_at: code_updated_at,
      total_installs: total_installs,
      daily_installs: daily_installs,
      sensitive: sensitive,
      script_type: script_type,
      fan_score: fan_score,
      site_application_id: script_applies_tos.map(&:site_application_id),
      locale: localized_attributes.map(&:locale_id).uniq,
      available_as_js: js? || css_convertible_to_js,
      available_as_css: css?,
    }
  end

  def search_value_from_localized_attributes(key)
    values = localized_attributes.select{|la| la.attribute_key == key}
    if key == 'additional_info'
      values.map!{|v| ApplicationController.helpers.format_user_text_as_plain(v.attribute_value, v.value_markup)}
    else
      values.map!(&:attribute_value)
    end
    values.join(' ')
  end

  def should_index?
    !unlisted? && !deleted? && !review_required?
  end
end
