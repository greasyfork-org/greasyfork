class ScriptAppliesTo < ApplicationRecord
  belongs_to :script
  belongs_to :site_application

  delegate :text, :domain, :domain?, to: :site_application
end
