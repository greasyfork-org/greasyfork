require 'application_system_test_case'

class HelpsTest < ApplicationSystemTestCase
  test '/help/external-scripts' do
    visit help_external_scripts_url
    assert_selector 'p', text: 'The current list is'
  end
end
