require 'application_system_test_case'

class ConversationsTest < ApplicationSystemTestCase
  test 'starting a conversation' do
    user = User.first
    login_as(user, scope: :user)

    to_user = User.second
    visit new_user_conversation_url(user, locale: :en)
    fill_in 'User', with: "https://greasyfork.org/users/#{to_user.id}"
    fill_in 'Message', with: '1 2 3 4'
    assert_difference -> { Conversation.count } => 1, -> { Message.count } => 1 do
      click_button 'Create conversation'
      assert_content "Conversation with #{to_user.name}"
    end

    assert_equal [user, to_user].sort, Conversation.last.users

    fill_in 'Message', with: '5 6 7 8'
    assert_difference -> { Conversation.count } => 0, -> { Message.count } => 1 do
      click_button 'Post reply'
      assert_content '5 6 7 8'
    end
  end

  test 'starting a conversation when it already exists' do
    user = users(:geoff)
    login_as(user, scope: :user)

    to_user = users(:junior)
    visit new_user_conversation_url(user, locale: :en)
    fill_in 'User', with: "https://greasyfork.org/users/#{to_user.id}"

    fill_in 'Message', with: '1 2 3 4'
    assert_difference -> { Conversation.count } => 0, -> { Message.count } => 1 do
      click_button 'Create conversation'
      assert_content "Conversation with #{to_user.name}"
    end
  end
end
