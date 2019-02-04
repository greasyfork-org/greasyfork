require "application_system_test_case"

class DerivativesTest < ApplicationSystemTestCase
  test "script derivatives" do
    script = Script.find(1)
    login_as(script.users.first, scope: :user)
    visit derivatives_script_url(script, locale: :en)
    assert_selector 'li', text: 'MyString by Gordon J. Canada'
  end
end
