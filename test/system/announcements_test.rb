require "application_system_test_case"

class AnnouncementsTest < ApplicationSystemTestCase
  setup do
    user = User.first
    login_as(user, scope: :user)
  end

  test "does not display when conditions don't match" do
    visit root_url
    assert_no_content "This is a test announcement"
  end

  test "can be dismissed" do
    visit root_url(locale: :en, test: 1)
    assert_content "This is a test announcement"
    within '.announcement' do
      click_button '✖'
    end
    assert_no_content "This is a test announcement"
    visit root_url(locale: :en, test: 1)
    assert_no_content "This is a test announcement"
  end
end
