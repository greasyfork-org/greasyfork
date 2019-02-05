require "application_system_test_case"

class ShowTest < ApplicationSystemTestCase
  test "all authors can see author links" do
    script = Script.find(2)
    assert_operator script.users.count, :>, 1
    script.users.each do |user|
      login_as(user, scope: :user)
      visit script_path(script, locale: :en)
      click_link 'Update'
    end
  end

  test "all authors should be listed" do
    script = Script.find(2)
    visit script_path(script, locale: :en)
    script.users.each do |user|
      assert_selector 'a', text: user.name
    end
  end
end
