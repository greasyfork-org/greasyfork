require 'application_system_test_case'

class AdminAdsTest < ApplicationSystemTestCase
  test 'loading the pending page' do
    login_as(users(:admin), scope: :user)
    assert_no_error_reported do
      visit pending_admin_ads_url
    end
  end
end
