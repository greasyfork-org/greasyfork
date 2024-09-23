require 'application_system_test_case'

module Users
  class NotificationSettingsTest < ::ApplicationSystemTestCase
    test 'updating notifications' do
      user = users(:one)
      login_as(user)
      user.update(subscribe_on_discussion: false)
      visit notification_settings_user_path(user, locale: :en)
      assert_changes -> { user.reload.subscribe_on_discussion }, to: true do
        check 'You start the discussion'
        click_on 'Update notification settings'
        assert_content 'Your notification preferences have been updated.'
      end
    end

    test 'unsubscribing from all' do
      user = users(:one)
      user.update(subscribe_on_discussion: true)
      DiscussionSubscription.create!(user:, discussion: Discussion.first)
      ConversationSubscription.create!(user:, conversation: Conversation.first)
      login_as(user)
      visit notification_settings_user_path(user, locale: :en)
      assert_difference -> { DiscussionSubscription.count } => -1 do
        assert_difference -> { ConversationSubscription.count } => -1 do
          assert_changes -> { user.reload.subscribe_on_discussion }, to: false do
            check 'You start the discussion'
            click_on 'Unsubscribe from all notifications'
            assert_content 'You have been unsubscribed from all notifications.'
          end
        end
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

    test 'unsubscribing from existing discussions' do
      user = users(:one)
      login_as(user)
      DiscussionSubscription.create!(user:, discussion: Discussion.first)
      visit notification_settings_user_path(user, locale: :en)
      assert_difference -> { DiscussionSubscription.count } => -1 do
        check 'Unsubscribe from the 1 discussion you are already subscribed to'
        click_on 'Update notification settings'
        assert_content 'Your notification preferences have been updated.'
      end
      visit notification_settings_user_path(user, locale: :en)
      assert_no_content 'you are already subscribed to'
    end

    test 'unsubscribing from existing conversations' do
      user = users(:one)
      login_as(user)
      ConversationSubscription.create!(user:, conversation: Conversation.first)
      visit notification_settings_user_path(user, locale: :en)
      assert_difference -> { ConversationSubscription.count } => -1 do
        check 'Unsubscribe from the 1 conversation you are already subscribed to'
        click_on 'Update notification settings'
        assert_content 'Your notification preferences have been updated.'
      end
      visit notification_settings_user_path(user, locale: :en)
      assert_no_content 'you are already subscribed to'
    end
  end
end
