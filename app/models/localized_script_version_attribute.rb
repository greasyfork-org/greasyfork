class LocalizedScriptVersionAttribute < ApplicationRecord
  include MentionsUsers

  belongs_to :script_version
  belongs_to :locale

  delegate :script, to: :script_version

  strip_attributes only: [:attribute_key, :attribute_value]

  validates :attribute_key, :attribute_value, :value_markup, presence: true
end
