require 'application_system_test_case'

class NotificationsTest < ApplicationSystemTestCase
  test 'no notifications' do
    user = users(:one)
    login_as(user)

    assert_notification_widget_count(0)

    visit notifications_url(user, locale: :en)
    assert_content 'No notifications yet!'
  end

  test 'a conversation notification' do
    user = users(:geoff)
    login_as(user)

    Notification.create!(user:, notification_type: Notification::NOTIFICATION_TYPE_NEW_CONVERSATION, item: conversations(:geoff_and_junior))

    visit notifications_url(user, locale: :en)
    assert_content 'Junior J. Junior, Sr. started a conversation with you: This is my message'
    assert_notification_widget_count(1)
  end

  test 'a message notification' do
    user = users(:junior)
    login_as(user)

    Notification.create!(user:, notification_type: Notification::NOTIFICATION_TYPE_NEW_MESSAGE, item: messages(:geoff_and_junior_1))

    visit notifications_url(user, locale: :en)
    assert_content 'Geoffrey sent you a message: This is my message'
  end

  def assert_notification_widget_count(count)
    if count == 0
      assert_no_selector('.notification-widget')
    else
      assert_selector('.notification-widget', text: count)
    end
  end
end
