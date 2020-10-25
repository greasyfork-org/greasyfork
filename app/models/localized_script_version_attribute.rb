class LocalizedScriptVersionAttribute < ApplicationRecord
  belongs_to :script_version
  belongs_to :locale

  strip_attributes only: [:attribute_key, :attribute_value]

  validates :attribute_key, :attribute_value, :locale, :value_markup, presence: true
end
