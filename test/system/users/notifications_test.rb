require 'application_system_test_case'

module Users
  class NotificationsTest < ::ApplicationSystemTestCase
    test 'updating notifications' do
      user = users(:one)
      login_as(user)
      user.update(subscribe_on_discussion: false)
      visit notifications_user_path(user, locale: :en)
      assert_changes -> { user.reload.subscribe_on_discussion }, to: true do
        check 'By default, subscribe to any discussions you start'
        click_button 'Update notification settings'
        assert_content 'Your notification preferences have been updated.'
      end
    end

    test 'unsubscribing from all' do
      user = users(:one)
      user.update(subscribe_on_discussion: true)
      login_as(user)
      visit notifications_user_path(user, locale: :en)
      assert_changes -> { user.reload.subscribe_on_discussion }, to: false do
        check 'By default, subscribe to any discussions you start'
        click_button 'Unsubscribe from all notifications'
        assert_content 'You have been unsubscribed from all notifications.'
      end
      visit notifications_user_path(user, locale: :en)
      assert_no_selector 'input[type=submit]', text: 'Unsubscribe from all notifications'
    end
  end
end
