require 'application_system_test_case'

module Users
  class ListTest < ::ApplicationSystemTestCase
    test 'can list users' do
      stub_es(User)
      visit users_path
      assert_content 'Gordon J. Canada'
    end
  end
end
