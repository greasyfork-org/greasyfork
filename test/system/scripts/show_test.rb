require "application_system_test_case"

class ShowTest < ApplicationSystemTestCase
  test "all authors can see author links" do
    script = Script.find(2)
    assert_operator script.users.count, :>, 1
    script.users.each do |user|
      login_as(user, scope: :user)
      visit script_path(script, locale: :en)
      assert_selector 'a', text: 'Update'
    end
  end
end
