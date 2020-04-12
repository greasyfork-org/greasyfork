require 'application_system_test_case'

class RegistrationTest < ApplicationSystemTestCase
  test 'password registration' do
    EmailAddress.stubs(:valid?).returns(true)
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

  test 'registration of banned email variant' do
    EmailAddress.stubs(:valid?).returns(true)
    visit root_url
    click_link 'Sign in'
    click_link 'Sign up'
    fill_in 'Name', with: 'Test Guy'
    fill_in 'Email', with: 'bannedguy+variant@gmail.com'
    fill_in 'Password', with: '12345678'
    fill_in 'Password confirmation', with: '12345678'
    click_button 'Sign up'
    assert_selector '#error_explanation', text: 'This email has been banned'
  end

  test 'registration then switching to banned email variant' do
    EmailAddress.stubs(:valid?).returns(true)
    visit root_url
    click_link 'Sign in'
    click_link 'Sign up'
    fill_in 'Name', with: 'Test Guy'
    fill_in 'Email', with: 'test@example.com'
    fill_in 'Password', with: '12345678'
    fill_in 'Password confirmation', with: '12345678'
    click_button 'Sign up'
    assert_selector '.notice', text: 'Welcome! You have signed up successfully.'
    click_link 'Test Guy'
    click_link 'Edit account'
    fill_in 'Email', with: 'bannedguy+variant@gmail.com'
    click_button 'Update'
    assert_selector '#error_explanation', text: 'This email has been banned'
  end

  test 'invalid email' do
    visit root_url
    click_link 'Sign in'
    click_link 'Sign up'
    fill_in 'Name', with: 'Test Guy'
    fill_in 'Email', with: 'test@example.com'
    fill_in 'Password', with: '12345678'
    fill_in 'Password confirmation', with: '12345678'
    click_button 'Sign up'
    assert_selector '#error_explanation', text: 'Email is invalid'
  end

  test 'email domain blocked from registration' do
    visit root_url
    click_link 'Sign in'
    click_link 'Sign up'
    fill_in 'Name', with: 'Test Guy'
    fill_in 'Email', with: 'test@reallybademail.com'
    fill_in 'Password', with: '12345678'
    fill_in 'Password confirmation', with: '12345678'
    click_button 'Sign up'
    assert_selector '#error_explanation', text: 'Email is invalid'
  end
end
