class ScriptReport < ApplicationRecord
  belongs_to :script
  belongs_to :reference_script, class_name: 'Script', optional: true
  belongs_to :reporter, class_name: 'User', optional: true

  scope :unresolved, -> { where(result: nil).joins(:script).merge(Script.not_deleted) }
  scope :unresolved_old, -> { unresolved.where(['script_reports.report_type IN (?) OR script_reports.created_at < ?', [TYPE_MALWARE, TYPE_SPAM, TYPE_OTHER], UNAUTHORIZED_CODE_WAIT_PERIOD.ago]) }

  scope :resolved, -> { where.not(result: nil) }
  scope :dismissed, -> { where(result: 'dismissed') }
  scope :upheld, -> { where(result: 'upheld') }

  scope :trusted_reporter, -> { joins(:reporter).where(users: { trusted_reports: true }) }
  scope :block_on_pending, -> { unresolved.trusted_reporter.where(report_type: [TYPE_MALWARE, TYPE_SPAM]) }

  validates :details, presence: true
  validates :reference_script, presence: true, if: ->(sr) { sr.unauthorized_code? }

  TYPE_UNAUTHORIZED_CODE = 'unauthorized_code'.freeze
  TYPE_MALWARE = 'malware'.freeze
  TYPE_SPAM = 'spam'.freeze
  TYPE_OTHER = 'other'.freeze

  UNAUTHORIZED_CODE_WAIT_PERIOD = 3.days

  def dismissed?
    result == 'dismissed'
  end

  def upheld?
    result == 'upheld'
  end

  def unauthorized_code?
    report_type == TYPE_UNAUTHORIZED_CODE
  end

  def uphold!(moderator_note = nil)
    update!(result: 'upheld', moderator_note: moderator_note.presence)
    reporter&.update_trusted_report!
  end

  def dismiss!(moderator_note = nil)
    update!(result: 'dismissed', moderator_note: moderator_note.presence)
    reporter&.update_trusted_report!
    AkismetSubmission.mark_as_ham(script)
  end

  def actionable?
    !unauthorized_code? || created_at < UNAUTHORIZED_CODE_WAIT_PERIOD.ago
  end

  def akismet?
    auto_reporter == 'akismet'
  end
end
