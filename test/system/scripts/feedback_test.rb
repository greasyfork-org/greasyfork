require "application_system_test_case"

class FeedbackTest < ApplicationSystemTestCase
  test 'reaching the report form' do
    user = users(:consumer)
    user.password = 'password'
    user.save!

    visit script_url(Script.first, locale: :en)
    click_link 'report the script'
    click_link 'the expedited report form'
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button 'Log in'
    assert_selector "p", text: "This page is for reporting cases"
  end
end
