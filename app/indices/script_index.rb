require 'thinking_sphinx/deltas/test_delta'

ThinkingSphinx::Index.define :script, with: :active_record, delta: Rails.env.test? ? ThinkingSphinx::Deltas::TestDelta : ThinkingSphinx::Deltas::SidekiqDelta do
  # fields
  # indexes localized_names.attribute_value, :as => 'name'
  # indexes localized_descriptions.attribute_value, :as => 'description'
  # indexes localized_additional_infos.attribute_value, :as => 'additional_info'
  indexes localized_attributes.attribute_value, as: 'combined_text'

  indexes users.name, as: :author

  # attributes
  has :created_at, :code_updated_at, :total_installs, :daily_installs, :default_name, :sensitive, :script_type_id
  # int is default and unsigned, we deal with negatives
  has :fan_score, type: :bigint
  has script_applies_tos.site_application_id, as: 'site_application_id'
  has localized_attributes.locale_id, as: 'locale'
  has "language = 'js' OR css_convertible_to_js = TRUE", as: 'available_as_js', type: :boolean
  has "language = 'css'", as: 'available_as_css', type: :boolean

  where 'script_type_id IN (1,3) and script_delete_type_id is null and review_state != "required"'

  set_property field_weights: {
    # name: 10,
    combined_text: 10,
    author: 5,
    # description: 2,
    # additional_info: 1,
  }
end
