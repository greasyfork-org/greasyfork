require 'active_support/concern'

module NotificationDisplay
  extend ActiveSupport::Concern

  included do
    before_action :load_notification_count
  end

  def load_notification_count
    return unless request.format.html?
    return unless current_user

    @notification_count = Notification.unread.where(user: current_user).count
  end
end