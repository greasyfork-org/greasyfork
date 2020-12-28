class Report < ApplicationRecord
  REASON_SPAM = 'spam'.freeze
  REASON_ABUSE = 'abuse'.freeze
  REASON_ILLEGAL = 'illegal'.freeze

  REASON_TEXT = {
    REASON_SPAM => 'spam',
    REASON_ABUSE => 'abusive or hateful content',
    REASON_ILLEGAL => 'malware or illegal content',
  }.freeze

  RESULT_DISMISSED = 'dismissed'.freeze
  RESULT_UPHELD = 'upheld'.freeze

  scope :unresolved, -> { where(result: nil) }
  scope :resolved, -> { where.not(result: nil) }
  scope :upheld, -> { where(result: RESULT_UPHELD) }

  belongs_to :item, polymorphic: true
  belongs_to :reporter, class_name: 'User', inverse_of: :reports_as_reporter, optional: true

  validates :reason, inclusion: { in: [REASON_SPAM, REASON_ABUSE, REASON_ILLEGAL] }, presence: true
  validates :reporter, presence: true, if: -> { auto_reporter.nil? }

  def dismiss!
    update!(result: RESULT_DISMISSED)
    item.discussion.update!(review_reason: nil) if item.is_a?(Comment) && item.first_comment?
    reporter&.update_trusted_report!
    AkismetSubmission.mark_as_ham(item)
  end

  def uphold!(moderator:, ban_user: false, delete_comments: false, delete_scripts: false)
    Report.transaction do
      case item
      when User, Message
        reported_user.ban!(moderator: moderator, delete_comments: delete_comments, delete_scripts: delete_scripts, ban_related: true, report: self)
      when Comment
        reported_user.ban!(moderator: moderator, delete_comments: delete_comments, delete_scripts: delete_scripts, ban_related: true, report: self) if ban_user
        item.soft_destroy!(by_user: moderator) unless item.soft_deleted?
      else
        raise "Unknown report item #{item}"
      end

      update!(result: RESULT_UPHELD)
      reporter&.update_trusted_report!
    end
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

  def reported_user
    case item
    when User
      item
    when Comment, Message
      item.poster
    else
      raise 'Unknown type'
    end
  end

  def reported_user_id
    case item
    when User
      item_id
    when Comment, Message
      item.poster_id
    else
      raise 'Unknown type'
    end
  end
end
