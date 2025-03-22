class ScriptAppliesTo < ApplicationRecord
  belongs_to :script
  belongs_to :site_application

  delegate :text, :domain_text, :domain?, to: :site_application

  after_destroy do
    # Destroy the site_application if it's not being used. Check for:
    # 1. New ScriptAppliesTo on this script that will be using it.
    # 2. ScriptAppliesTos on other scripts.
    site_application.destroy if script.script_applies_tos.reject(&:marked_for_destruction?).none? { |sat| sat != self && sat.site_application == site_application } && ScriptAppliesTo.where(site_application_id:).none?
  end

  after_commit do
    # site_applications is a has_many through this, and it doesn't seem to update when this is changed.
    script.site_applications.reset if association(:script).loaded?
  end
end
