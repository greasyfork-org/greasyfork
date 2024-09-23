class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :item, polymorphic: true

  scope :unread, -> { where(read_at: nil) }

  NOTIFICATION_TYPE_NEW_CONVERSATION = :new_conversation
  NOTIFICATION_TYPE_NEW_MESSAGE = :new_message
  NOTIFICATION_TYPE_REPORT_RESOLVED_REPORTER = :report_resolved_reporter
  NOTIFICATION_TYPE_REPORT_FILED_REPORTED = :report_filed_reported
  NOTIFICATION_TYPE_REPORT_RESOLVED_REPORTED = :report_resolved_reported
  NOTIFICATION_TYPE_REPORT_REBUTTED_REPORTER = :report_rebutted_reporter
  NOTIFICATION_TYPE_NEW_COMMENT = :new_comment
  NOTIFICATION_TYPE_MENTION = :mention

  enum :notification_type, {
    NOTIFICATION_TYPE_NEW_CONVERSATION => 0,
    NOTIFICATION_TYPE_NEW_MESSAGE => 1,
    NOTIFICATION_TYPE_REPORT_RESOLVED_REPORTER => 2,
    NOTIFICATION_TYPE_REPORT_FILED_REPORTED => 3,
    NOTIFICATION_TYPE_REPORT_RESOLVED_REPORTED => 4,
    NOTIFICATION_TYPE_REPORT_REBUTTED_REPORTER => 5,
    NOTIFICATION_TYPE_NEW_COMMENT => 6,
    NOTIFICATION_TYPE_MENTION => 7,
  }

  def self.mark_read!
    unread.update_all(read_at: Time.zone.now)
  end

  def read?
    read_at.present?
  end

  def path(locale:)
    case item
    when Conversation, Message
      item.path(user, locale:)
    else
      item.path(locale:)
    end
  end
end
