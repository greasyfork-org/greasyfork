class Report < ApplicationRecord
  include HasAttachments

  REASON_SPAM = 'spam'.freeze
  REASON_ABUSE = 'abuse'.freeze
  REASON_ILLEGAL = 'illegal'.freeze
  REASON_UNAUTHORIZED_CODE = 'unauthorized_code'.freeze
  REASON_MALWARE = 'malware'.freeze
  REASON_MINIFIED = 'minified'.freeze
  REASON_EXTERNAL_CODE = 'external_code'.freeze
  REASON_UNDISCLOSED_ANTIFEATURE = 'undisclosed_antifeature'.freeze
  REASON_OTHER = 'other'.freeze

  REASON_TEXT = {
    REASON_SPAM => 'spam',
    REASON_ABUSE => 'abusive or hateful content',
    REASON_ILLEGAL => 'illegal content',
    REASON_UNAUTHORIZED_CODE => 'unauthorized copy',
    REASON_MALWARE => 'malware',
    REASON_MINIFIED => 'minified code',
    REASON_EXTERNAL_CODE => 'disallowed external code',
    REASON_UNDISCLOSED_ANTIFEATURE => 'undisclosed antifeature',
    REASON_OTHER => 'other',
  }.freeze

  NON_SCRIPT_REASONS = [REASON_SPAM, REASON_ABUSE, REASON_ILLEGAL].freeze

  RESULT_DISMISSED = 'dismissed'.freeze
  RESULT_UPHELD = 'upheld'.freeze

  scope :unresolved, -> { where(result: nil) }
  scope :resolved, -> { where.not(result: nil) }
  scope :upheld, -> { where(result: RESULT_UPHELD) }
  scope :block_on_pending, -> { unresolved.trusted_reporter }
  scope :trusted_reporter, -> { joins(:reporter).where(users: { trusted_reports: true }) }

  belongs_to :item, polymorphic: true
  belongs_to :reporter, class_name: 'User', inverse_of: :reports_as_reporter, optional: true
  belongs_to :reference_script, class_name: 'Script', optional: true
  belongs_to :rebuttal_by_user, class_name: 'User', optional: true

  validates :reason, inclusion: { in: NON_SCRIPT_REASONS }, presence: true, unless: -> { item.is_a?(Script) }
  validates :reason, inclusion: { in: REASON_TEXT.keys, message: :invalid }, presence: true, if: -> { item.is_a?(Script) }
  validates :reporter, presence: true, if: -> { auto_reporter.nil? }
  validates :explanation_markup, inclusion: { in: %w[html markdown text] }, presence: true

  def dismiss!(moderator_notes:)
    update!(result: RESULT_DISMISSED, moderator_notes: moderator_notes)
    item.discussion.update!(review_reason: nil) if item.is_a?(Comment) && item.first_comment?
    reporter&.update_trusted_report!
    AkismetSubmission.mark_as_ham(item)
  end

  def uphold!(moderator:, moderator_notes: nil, ban_user: false, delete_comments: false, delete_scripts: false)
    Report.transaction do
      case item
      when User, Message
        reported_users.each { |user| user.ban!(moderator: moderator, delete_comments: delete_comments, delete_scripts: delete_scripts, ban_related: true, report: self) }
      when Comment
        reported_users.each { |user| user.ban!(moderator: moderator, delete_comments: delete_comments, delete_scripts: delete_scripts, ban_related: true, report: self) } if ban_user
        item.soft_destroy!(by_user: moderator) unless item.soft_deleted?
      when Script
        if unauthorized_code? && reference_script
          item.update!(script_delete_type_id: ScriptDeleteType::KEEP, locked: true, replaced_by_script: reference_script, self_deleted: moderator.nil?, delete_reason: "Report ##{id}")
        else
          item.update!(script_delete_type_id: ScriptDeleteType::BLANKED, locked: true, self_deleted: moderator.nil?, delete_reason: "Report ##{id}")
        end
        if ban_user
          reported_users.each { |user| user.ban!(moderator: moderator, delete_comments: delete_comments, delete_scripts: delete_scripts, ban_related: true, report: self) }
        elsif moderator
          ModeratorAction.create!(moderator: moderator, script: item, action: 'Delete and lock', report: self)
        end
      else
        raise "Unknown report item #{item}"
      end

      update!(result: RESULT_UPHELD, moderator_notes: moderator_notes)
      reporter&.update_trusted_report!
    end

    Report.unresolved.where(item: item).find_each do |other_report|
      other_report.update!(result: RESULT_UPHELD)
      other_report.reporter&.update_trusted_report!
    end
  end

  def rebut!(rebuttal:, by:)
    update!(rebuttal: rebuttal, rebuttal_by_user: by)
  end

  def reason_text
    REASON_TEXT[reason]
  end

  def resolved?
    result.nil?
  end

  def dismissed?
    result == RESULT_DISMISSED
  end

  def upheld?
    result == RESULT_UPHELD
  end

  def reported_users
    case item
    when User
      [item]
    when Comment, Message
      [item.poster]
    when Script
      item.users
    else
      raise 'Unknown type'
    end.compact
  end

  def reported_user_id
    case item
    when User
      item_id
    when Comment, Message
      item.poster_id
    when Script
      item.authors.first&.user_id
    else
      raise 'Unknown type'
    end
  end

  def unauthorized_code?
    reason == REASON_UNAUTHORIZED_CODE
  end
end
