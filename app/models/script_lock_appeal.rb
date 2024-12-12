class ScriptLockAppeal < ApplicationRecord
  belongs_to :script
  belongs_to :report, optional: true

  enum :resolution, { unresolved: 0, dismissed: 1, unlocked: 2 }

  validates :text_markup, inclusion: { in: %w[html markdown] }, presence: true
  validates :text, presence: true, length: { maximum: 10_000 }

  def other_appeals_on_report
    return ScriptLockAppeal.none unless report_id

    ScriptLockAppeal.where.not(id:).where(report_id:)
  end
end
