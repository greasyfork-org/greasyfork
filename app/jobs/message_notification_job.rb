class MessageNotificationJob < ApplicationJob
  def perform(message)
    message.send_notifications!
  end
end
