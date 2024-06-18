class ScriptAppliesTo < ApplicationRecord
  belongs_to :script
  belongs_to :site_application

  delegate :text, :domain_text, :domain?, to: :site_application

  after_destroy do
    site_application.destroy if ScriptAppliesTo.where(site_application_id:).none?
  end
end
