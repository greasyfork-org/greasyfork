require 'application_system_test_case'

class DerivativesTest < ApplicationSystemTestCase
  test 'script derivatives' do
    script = Script.find(1)
    login_as(script.users.first, scope: :user)
    with_sphinx do
      visit derivatives_script_url(script, locale: :en)
    end
  end
end
