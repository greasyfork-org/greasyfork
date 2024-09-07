class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :item, polymorphic: true

  scope :unread, -> { where(read_at: nil) }

  NOTIFICATION_TYPE_NEW_CONVERSATION = :new_conversation
  NOTIFICATION_TYPE_NEW_MESSAGE = :new_message

  enum :notification_type, [NOTIFICATION_TYPE_NEW_CONVERSATION, NOTIFICATION_TYPE_NEW_MESSAGE]

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
