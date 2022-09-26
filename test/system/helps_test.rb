require 'application_system_test_case'

class HelpsTest < ApplicationSystemTestCase
  test '/help/external-scripts' do
    visit help_external_scripts_url
    assert_selector 'p', text: 'User scripts have the technical ability to load and execute other scripts.'
  end

  test '/help/cdns' do
    visit help_cdns_url
    assert_selector 'p', text: 'This is a list of CDNs'
  end
end
