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
  end
end
