require 'application_system_test_case'

module Users
  class ShowTest < ::ApplicationSystemTestCase
    test 'can show a user' do
      visit user_path(id: users(:consumer))
      assert_content 'Gordon J. Canada'
    end
  end
end
