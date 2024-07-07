require 'application_system_test_case'

module Users
  class ListTest < ::ApplicationSystemTestCase
    test 'can list users' do
      User.expects(:search).returns(User.all.paginate(page: 1))

      visit users_path
      assert_content 'Gordon J. Canada'
    end
  end
end
