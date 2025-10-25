require 'application_system_test_case'

module Users
  class AdminTest < ::ApplicationSystemTestCase
    test 'can mark email as confirmed' do
      login_as(users(:mod))

      user = users(:junior)
      user.update!(confirmed_at: nil)
      assert_not user.confirmed?

      visit user_path(user, locale: :en)
      click_link 'Mark email as confirmed'
      assert_content 'Email marked as confirmed'
      assert user.reload.confirmed?
    end

    test 'can ban' do
      login_as(users(:mod))

      user = users(:geoff)
      visit user_path(user, locale: :en)
      click_link 'Ban'
      choose 'Spam'
      fill_in 'explanation', with: 'Posting spam links'
      check "Delete user's 1 comment"

      assert_difference -> { ModeratorAction.count } => 1 do
        click_button 'Ban'
        assert_content 'has been banned'
      end

      assert user.reload.banned?
      assert user.discussions.first.soft_deleted?
      assert user.discussions.first.spam_deleted
      assert user.discussions.first.comments.first.spam_deleted
      assert_equal 'Spam: Posting spam links', ModeratorAction.last.reason
    end
  end
end
