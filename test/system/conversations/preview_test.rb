require 'application_system_test_case'

module Conversations
  class PreviewTest < ApplicationSystemTestCase
    test 'previewing content in a new conversation' do
      user = User.first
      user.update!(preferred_markup: 'markdown')
      login_as(user, scope: :user)

      visit new_user_conversation_url(user, locale: :en)
      fill_in 'Message', with: '1 *2* 3 4'
      find('.preview-tab').click
      assert_content '1 2 3 4'
    end

    test 'previewing content in an existing conversation' do
      user = users(:geoff)
      user.update!(preferred_markup: 'markdown')
      login_as(user, scope: :user)
      conversation = conversations(:geoff_and_junior)

      visit user_conversation_url(user, conversation, locale: :en)

      fill_in 'Message', with: '1 *2* 3 4'
      find('.preview-tab').click
      assert_content '1 2 3 4'
    end
  end
end
