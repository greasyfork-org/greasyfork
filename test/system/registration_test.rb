require "application_system_test_case"

class RegistrationTest < ApplicationSystemTestCase
  test "password registration" do
    visit root_url
    click_link 'Sign in'
    click_link 'Sign up'
    fill_in 'Name', with: 'Test Guy'
    fill_in 'Email', with: 'test@example.com'
    fill_in 'Password', with: '12345678'
    fill_in 'Password confirmation', with: '12345678'
    click_button 'Sign up'
    assert_selector '.notice', text: 'Welcome! You have signed up successfully.'
  end
end
