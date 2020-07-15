class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :poster, class_name: 'User'

  has_many_attached :attachments

  validates :content, presence: true, length: { maximum: 10_000 }
  validates :content_markup, presence: true, inclusion: { in: %w[html markdown] }

  validates :attachments,
            content_type: %w[image/png image/jpg image/jpeg],
            size: { less_than: Rails.configuration.screenshot_max_size },
            limit: { max: Rails.configuration.screenshot_max_count }

  after_commit do
    conversation.update_stats! unless conversation.destroyed?
  end

  def first_message?
    conversation.messages.order(:id).first.id == id
  end

  def send_notifications!
    (conversation.users - [poster]).each do |user|
      if first_message?
        ConversationMailer.new_conversation(conversation, user, conversation.messages.first.poster).deliver_later
      else
        ConversationMailer.new_message(self, user).deliver_later
      end
    end
  end
end
