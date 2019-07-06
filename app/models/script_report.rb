class ScriptReport < ApplicationRecord
  belongs_to :script
  belongs_to :reference_script, class_name: 'Script', optional: true

  scope :unresolved, -> { where(resolved: false).joins(:script) }
  scope :unresolved_old, -> { unresolved.where(['script_reports.created_at < ?', 3.days.ago]) }
  
  validates :copy_details, :additional_info, presence: true
  validates :reference_script, presence: true, if: -> (sr) { sr.unauthorized_code? }

  TYPE_UNAUTHORIZED_CODE = 'unauthorized_code'

  def dismissed?
    resolved? && !script.locked?
  end

  def upheld?
    resolved? && script.locked?
  end

  def unauthorized_code?
    report_type == TYPE_UNAUTHORIZED_CODE
  end
end
