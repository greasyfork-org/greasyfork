class ScriptReport < ApplicationRecord
  belongs_to :script
  belongs_to :reference_script, class_name: 'Script'

  scope :unresolved, -> { where(resolved: false) }
  scope :unresolved_old, -> { unresolved.where(['created_at < ?', 3.days.ago]) }
  
  validates :copy_details, :additional_info, presence: true

  def dismissed?
    resolved? && !script.locked?
  end

  def upheld?
    resolved? && script.locked?
  end
  
end
