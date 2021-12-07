require 'application_system_test_case'

class DerivativesTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  test 'script derivatives' do
    script = Script.find(1)
    login_as(script.users.first, scope: :user)
    with_sphinx do
      visit derivatives_script_url(script, locale: :en)
    end
    click_button 'Recheck now'
    assert_content 'Similarity check will be completed in a few minutes.'
  end
end
