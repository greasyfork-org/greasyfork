class UserNotificationSetting < ApplicationRecord
  belongs_to :user

  DELIVERY_TYPE_ON_SITE = :on_site
  DELIVERY_TYPE_EMAIL = :email

  enum :notification_type, { Notification::NOTIFICATION_TYPE_NEW_CONVERSATION => 0, Notification::NOTIFICATION_TYPE_NEW_MESSAGE => 1 }
  enum :delivery_type, { DELIVERY_TYPE_ON_SITE => 0, DELIVERY_TYPE_EMAIL => 1 }

  DEFAULT_NOTIFICATIONS = {
    new_conversation: [DELIVERY_TYPE_ON_SITE, DELIVERY_TYPE_EMAIL],
    new_message: [DELIVERY_TYPE_ON_SITE, DELIVERY_TYPE_EMAIL],
  }.freeze

  def self.delivery_types_for_user(user, notification_type)
    saved_prefs = where(user:, notification_type:).index_by { |uns| uns.delivery_type.to_sym }
    [DELIVERY_TYPE_EMAIL, DELIVERY_TYPE_ON_SITE].select { |delivery_type| saved_prefs[delivery_type].present? ? saved_prefs[delivery_type].enabled : DEFAULT_NOTIFICATIONS[notification_type].include?(delivery_type) }
  end

  def self.update_delivery_types_for_user(user, notification_type, delivery_types)
    delivery_types.map!(&:to_sym)
    [DELIVERY_TYPE_EMAIL, DELIVERY_TYPE_ON_SITE].each do |delivery_type|
      uns = find_or_initialize_by(user:, notification_type:, delivery_type:)
      uns.enabled = delivery_types.include?(delivery_type)
      uns.save!
    end
  end
end
