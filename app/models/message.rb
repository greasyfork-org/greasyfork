class Message < ApplicationRecord
  include HasAttachments
  include MentionsUsers

  belongs_to :conversation
  belongs_to :poster, class_name: 'User'

  validates :content, presence: true, length: { maximum: 10_000 }
  validates :content_markup, presence: true, inclusion: { in: %w[html markdown] }

  after_commit do
    conversation.update_stats! unless conversation.destroyed?
  end

  def first_message?
    conversation.messages.order(:id).first.id == id
  end

  def send_notifications!
    (conversation.users - [poster]).select { |user| user.subscribed_to_conversation?(conversation) }.each do |user|
      delivery_types = UserNotificationSetting.delivery_types_for_user(user, first_message? ? :new_conversation : :new_message)
      if delivery_types.include?(UserNotificationSetting::DELIVERY_TYPE_ON_SITE)
        if first_message?
          Notification.create!(user:, item: conversation, notification_type: Notification::NOTIFICATION_TYPE_NEW_CONVERSATION)
        else
          Notification.create!(user:, item: self, notification_type: Notification::NOTIFICATION_TYPE_NEW_CONVERSATION)
        end
      end
      if delivery_types.include?(UserNotificationSetting::DELIVERY_TYPE_EMAIL)
        if first_message?
          ConversationMailer.new_conversation(conversation, user, conversation.messages.first.poster).deliver_later
        else
          ConversationMailer.new_message(self, user).deliver_later
        end
      end
    end
  end

  EDITABLE_PERIOD = 5.minutes

  def editable_by?(user)
    return false if new_record?
    return false unless user
    return false unless poster == user

    created_at >= EDITABLE_PERIOD.ago
  end

  def path(user, locale:)
    conversation.path_for_message(user, self, locale:)
  end

  def plain_text
    ApplicationController.helpers.format_user_text_as_plain(content, content_markup)
  end
end
