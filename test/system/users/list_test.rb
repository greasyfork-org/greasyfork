require "application_system_test_case"

class User::ListTest < ApplicationSystemTestCase
  test "can list users" do
    visit users_path
    assert_content 'Gordon J. Canada'
  end
end
