class ScriptReport < ApplicationRecord
  belongs_to :script
  belongs_to :reference_script, class_name: 'Script'

  scope :unresolved, -> { where(resolved: false).joins(:script) }
  scope :unresolved_old, -> { unresolved.where(['script_reports.created_at < ?', 3.days.ago]) }
  
  validates :copy_details, :additional_info, presence: true

  TYPE_UNAUTHORIZED_CODE = 'unauthorized_code'

  def dismissed?
    resolved? && !script.locked?
  end

  def upheld?
    resolved? && script.locked?
  end
  
end
