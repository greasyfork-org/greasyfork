module InactiveUser
  extend ActiveSupport::Concern

  INACTIVE_PERIOD = 5.years
  DELETE_AFTER_NOTIFICATION = 1.month

  included do
    scope :no_content, -> { where.missing(:scripts, :discussions, :comments, :reports_as_reporter) }
    scope :inactive_notifiable, -> { no_content.where(current_sign_in_at: ...INACTIVE_PERIOD.ago, inactive_notification_sent_at: nil).order(:current_sign_in_at) }
    scope :inactive_deletable, -> { where(current_sign_in_at: ...INACTIVE_PERIOD.ago, inactive_notification_sent_at: ...DELETE_AFTER_NOTIFICATION.ago).order(:inactive_notification_sent_at) }
  end

  def inactive_deletion_at
    (inactive_notification_sent_at || Time.zone.now) + DELETE_AFTER_NOTIFICATION
  end

  def send_inactive_notification_email!
    InactiveUserMailer.notify(self).deliver_later
    update!(inactive_notification_sent_at: Time.current)
  end
end
