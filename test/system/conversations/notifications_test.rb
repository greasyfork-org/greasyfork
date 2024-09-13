require 'application_system_test_case'

module Conversations
  class NotificationsTest < ApplicationSystemTestCase
    include ActiveJob::TestHelper

    def start_conversation(as_user, to_user, change_subscription_state: nil)
      login_as(as_user, scope: :user)

      visit new_user_conversation_url(as_user, locale: :en, other_user: to_user.name)
      fill_in 'Message', with: 'This is a test'

      case change_subscription_state
      when true
        check 'Notify me of any replies'
      when false
        uncheck 'Notify me of any replies'
      end

      click_on 'Create conversation'

      assert_content "Conversation with #{to_user.name}"
      perform_enqueued_jobs
    end

    def reply(as_user, conversation)
      ActionMailer::Base.deliveries.clear
      login_as(as_user, scope: :user)

      visit user_conversation_url(as_user, conversation, locale: :en)
      fill_in 'Message', with: 'This is a reply'
      click_on 'Post reply'

      assert_content 'This is a reply'
      # Once for MessageNotificationJob, once for the mail job.
      perform_enqueued_jobs
      perform_enqueued_jobs
    end

    test 'notifications on start to the other user when they subscribe by default' do
      ActionMailer::Base.deliveries.clear
      user = User.first
      to_user = users(:junior)
      to_user.update!(subscribe_on_conversation_receiver: true)

      assert_difference -> { Notification.where(user: to_user).count } => 1 do
        start_conversation(user, to_user)
      end

      mail = ActionMailer::Base.deliveries.last
      assert_not_nil mail
      assert_equal [to_user.email], mail.to

      logout
      login_as(to_user)
      assert_difference -> { Notification.unread.where(user: to_user).count } => -1 do
        visit user_conversation_url(to_user, Conversation.last, locale: :en)
      end
    end

    test "no notifications on start to the other user when they don't subscribe by default" do
      ActionMailer::Base.deliveries.clear
      user = User.first
      to_user = users(:junior)
      to_user.update!(subscribe_on_conversation_receiver: false)

      assert_difference -> { Notification.where(user: to_user).count } => 0 do
        start_conversation(user, to_user)
      end

      mail = ActionMailer::Base.deliveries.last
      assert_nil mail
    end

    test 'no notifications on start to the other user when notifications are disabled' do
      ActionMailer::Base.deliveries.clear
      user = User.first
      to_user = users(:junior)
      to_user.update!(subscribe_on_conversation_receiver: true)
      UserNotificationSetting.update_delivery_types_for_user(to_user, :new_conversation, [])

      assert_difference -> { Notification.where(user: to_user).count } => 0 do
        start_conversation(user, to_user)
      end

      mail = ActionMailer::Base.deliveries.last
      assert_nil mail
    end

    test 'notifications on reply when the other user is subscribed by default' do
      ActionMailer::Base.deliveries.clear
      user = User.first
      user.update!(subscribe_on_conversation_starter: true)
      to_user = users(:junior)

      start_conversation(user, to_user)

      logout

      assert_difference -> { Notification.where(user:).count } => 1 do
        reply(to_user, Conversation.last)
      end

      mail = ActionMailer::Base.deliveries.last
      assert_not_nil mail
      assert_equal [user.email], mail.to

      logout
      login_as(user)
      assert_difference -> { Notification.unread.where(user:).count } => -1 do
        visit user_conversation_url(user, Conversation.last, locale: :en)
      end
    end

    test 'no notifications on reply when the other user is not subscribed by default' do
      ActionMailer::Base.deliveries.clear
      user = User.first
      user.update!(subscribe_on_conversation_starter: false)
      to_user = users(:junior)

      start_conversation(user, to_user)

      logout

      reply(to_user, Conversation.last)

      mail = ActionMailer::Base.deliveries.last
      assert_nil mail
    end

    test 'no notifications on reply when the other user chooses not to subscribe' do
      ActionMailer::Base.deliveries.clear
      user = User.first
      user.update!(subscribe_on_conversation_starter: true)
      to_user = users(:junior)

      start_conversation(user, to_user, change_subscription_state: false)

      logout

      reply(to_user, Conversation.last)

      mail = ActionMailer::Base.deliveries.last
      assert_nil mail
    end

    test 'no notifications on reply when the other user has notifications turned off' do
      ActionMailer::Base.deliveries.clear
      user = User.first
      user.update!(subscribe_on_conversation_starter: true)
      to_user = users(:junior)
      UserNotificationSetting.update_delivery_types_for_user(user, :new_message, [])

      start_conversation(user, to_user)

      logout

      assert_difference -> { Notification.where(user:).count } => 0 do
        reply(to_user, Conversation.last)
      end

      mail = ActionMailer::Base.deliveries.last
      assert_nil mail
    end
  end
end
