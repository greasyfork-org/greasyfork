require 'application_system_test_case'

module Conversations
  class NotificationsTest < ApplicationSystemTestCase
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

      click_button 'Create conversation'

      assert_content "Conversation with #{to_user.name}"
    end

    def reply(as_user, conversation)
      ActionMailer::Base.deliveries.clear
      login_as(as_user, scope: :user)

      visit user_conversation_url(as_user, conversation, locale: :en)
      fill_in 'Message', with: 'This is a reply'
      click_button 'Post reply'

      assert_content 'This is a reply'
    end

    test 'notifications on start to the other user when they subscribe by default' do
      ActionMailer::Base.deliveries.clear
      user = User.first
      to_user = users(:junior)
      to_user.update!(subscribe_on_conversation_receiver: true)

      start_conversation(user, to_user)

      mail = ActionMailer::Base.deliveries.last
      assert_not_nil mail
      assert_equal [to_user.email], mail.to
    end

    test "no notifications on start to the other user when they don't subscribe by default" do
      ActionMailer::Base.deliveries.clear
      user = User.first
      to_user = users(:junior)
      to_user.update!(subscribe_on_conversation_receiver: false)

      start_conversation(user, to_user)

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

      reply(to_user, Conversation.last)

      mail = ActionMailer::Base.deliveries.last
      assert_not_nil mail
      assert_equal [user.email], mail.to
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
  end
end
