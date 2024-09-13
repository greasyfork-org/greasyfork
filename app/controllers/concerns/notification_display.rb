require 'active_support/concern'

module NotificationDisplay
  extend ActiveSupport::Concern

  included do
    before_action :load_notification_count
    helper_method :notification_widget_count
  end

  def load_notification_count
    return unless request.format.html?
    return unless current_user

    @notification_count = Notification.unread.where(user: current_user).count
  end

  def notification_widget_count
    return nil unless @notification_count
    return nil if @notification_count == 0
    return '+' if @notification_count > 9

    @notification_count
  end
end
