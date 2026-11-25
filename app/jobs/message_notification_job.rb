class MessageNotificationJob < ApplicationJob
  discard_on ActiveJob::DeserializationError

  def perform(message)
    message.send_notifications!
  end
end
