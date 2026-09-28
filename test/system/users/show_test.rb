require 'application_system_test_case'

module Users
  class ShowTest < ::ApplicationSystemTestCase
    test 'can show a user' do
      visit user_path(id: users(:consumer))
      assert_content 'Gordon J. Canada'
    end

    test 'unlisted scripts show in the proper section for the author' do
      unlisted_script = scripts(:unlisted)
      user = unlisted_script.users.first
      login_as(user)
      visit user_path(id: user.id)
      assert_no_selector '#user-script-list-section', text: unlisted_script.default_name
      assert_selector '#user-unlisted-script-list-section', text: unlisted_script.default_name
    end
  end
end
