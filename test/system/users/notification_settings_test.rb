require 'application_system_test_case'

module Users
  class NotificationSettingsTest < ::ApplicationSystemTestCase
    test 'updating notifications' do
      user = users(:one)
      login_as(user)
      user.update(subscribe_on_discussion: false)
      visit notification_settings_user_path(user, locale: :en)
      assert_changes -> { user.reload.subscribe_on_discussion }, to: true do
        check 'By default, subscribe to any discussions you start'
        click_on 'Update notification settings'
        assert_content 'Your notification preferences have been updated.'
      end
    end

    test 'unsubscribing from all' do
      user = users(:one)
      user.update(subscribe_on_discussion: true)
      login_as(user)
      visit notification_settings_user_path(user, locale: :en)
      assert_changes -> { user.reload.subscribe_on_discussion }, to: false do
        check 'By default, subscribe to any discussions you start'
        click_on 'Unsubscribe from all notifications'
        assert_content 'You have been unsubscribed from all notifications.'
      end
      visit notification_settings_user_path(user, locale: :en)
      assert_no_selector 'input[type=submit]', text: 'Unsubscribe from all notifications'
    end

    test 'changing a notification setting from default' do
      user = users(:one)
      assert_empty user.user_notification_settings
      assert_equal [UserNotificationSetting::DELIVERY_TYPE_EMAIL, UserNotificationSetting::DELIVERY_TYPE_ON_SITE], UserNotificationSetting.delivery_types_for_user(user, :new_conversation)
      assert_equal [UserNotificationSetting::DELIVERY_TYPE_EMAIL, UserNotificationSetting::DELIVERY_TYPE_ON_SITE], UserNotificationSetting.delivery_types_for_user(user, :new_message)
      login_as(user)

      # Leave as normal and save
      visit notification_settings_user_path(user, locale: :en)
      within '#notification-setting-new_conversation' do
        assert_checked_field 'On site'
        assert_checked_field 'By email'
      end
      within '#notification-setting-new_message' do
        assert_checked_field 'On site'
        assert_checked_field 'By email'
      end
      click_on 'Update notification settings'
      assert_content 'Your notification preferences have been updated.'
      assert_equal [UserNotificationSetting::DELIVERY_TYPE_EMAIL, UserNotificationSetting::DELIVERY_TYPE_ON_SITE], UserNotificationSetting.delivery_types_for_user(user, :new_conversation)
      assert_equal [UserNotificationSetting::DELIVERY_TYPE_EMAIL, UserNotificationSetting::DELIVERY_TYPE_ON_SITE], UserNotificationSetting.delivery_types_for_user(user, :new_message)
      visit notification_settings_user_path(user, locale: :en)
      within '#notification-setting-new_conversation' do
        assert_checked_field 'On site'
        assert_checked_field 'By email'
      end
      within '#notification-setting-new_message' do
        assert_checked_field 'On site'
        assert_checked_field 'By email'
      end

      # Uncheck and save
      within '#notification-setting-new_conversation' do
        uncheck 'On site'
        uncheck 'By email'
      end
      within '#notification-setting-new_message' do
        uncheck 'On site'
        uncheck 'By email'
      end

      click_on 'Update notification settings'
      assert_content 'Your notification preferences have been updated.'
      assert_empty UserNotificationSetting.delivery_types_for_user(user, :new_conversation)
      assert_empty UserNotificationSetting.delivery_types_for_user(user, :new_message)
    end
  end
end
