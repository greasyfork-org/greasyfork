require 'application_system_test_case'

module Users
  class ListTest < ::ApplicationSystemTestCase
    test 'can list users' do
      mock_search_result = User.all
      mock_search_result.stubs(:current_page).returns(1)
      mock_search_result.stubs(:total_count).returns(User.count)
      User.expects(:search).returns(mock_search_result)

      visit users_path
      assert_content 'Gordon J. Canada'
    end
  end
end
