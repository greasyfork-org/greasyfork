require 'application_system_test_case'

class RegistrationTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  test 'password registration' do
    EmailAddress.stubs(:valid?).returns(true)
    visit root_url
    click_on 'Sign in'
    click_on 'Sign up'
    fill_in 'Name', with: 'Test Guy'
    fill_in 'Email', with: 'test@example.com'
    fill_in 'Password', with: '12345678'
    fill_in 'Password confirmation', with: '12345678'
    click_on 'Sign up'
    assert_selector '.notice', text: 'Welcome! You have signed up successfully.'
  end

  test 'registration of banned email variant' do
    EmailAddress.stubs(:valid?).returns(true)
    visit root_url
    click_on 'Sign in'
    click_on 'Sign up'
    fill_in 'Name', with: 'Test Guy'
    fill_in 'Email', with: 'bannedguy+variant@gmail.com'
    fill_in 'Password', with: '12345678'
    fill_in 'Password confirmation', with: '12345678'
    click_on 'Sign up'
    assert_selector '#error_explanation', text: 'This email has been banned'
  end

  test 'registration then switching to banned email variant' do
    EmailAddress.stubs(:valid?).returns(true)
    visit root_url
    click_on 'Sign in'
    click_on 'Sign up'
    fill_in 'Name', with: 'Test Guy'
    fill_in 'Email', with: 'test@example.com'
    fill_in 'Password', with: '12345678'
    fill_in 'Password confirmation', with: '12345678'
    click_on 'Sign up'
    assert_selector '.notice', text: 'Welcome! You have signed up successfully.'
    click_on 'Test Guy'
    click_on 'Edit account'
    fill_in 'Email', with: 'bannedguy+variant@gmail.com'
    click_on 'Update'
    assert_selector '#error_explanation', text: 'This email has been banned'
  end

  test 'invalid email' do
    EmailAddress.stubs(:valid?).returns(false)
    visit root_url
    click_on 'Sign in'
    click_on 'Sign up'
    fill_in 'Name', with: 'Test Guy'
    fill_in 'Email', with: 'test@example.com'
    fill_in 'Password', with: '12345678'
    fill_in 'Password confirmation', with: '12345678'
    click_on 'Sign up'
    assert_selector '#error_explanation', text: 'Email is invalid'
  end

  test 'email domain blocked from registration' do
    visit root_url
    click_on 'Sign in'
    click_on 'Sign up'
    fill_in 'Name', with: 'Test Guy'
    fill_in 'Email', with: 'test@reallybademail.com'
    fill_in 'Password', with: '12345678'
    fill_in 'Password confirmation', with: '12345678'
    click_on 'Sign up'
    assert_selector '#error_explanation', text: 'Email is invalid'
  end

  test 'user name blocked from registration' do
    EmailAddress.stubs(:valid?).returns(true)
    BlockedUser.create!(pattern: 'Test')
    visit root_url
    click_on 'Sign in'
    click_on 'Sign up'
    fill_in 'Name', with: 'Test Guy'
    fill_in 'Email', with: 'test@example.com'
    fill_in 'Password', with: '12345678'
    fill_in 'Password confirmation', with: '12345678'
    click_on 'Sign up'
    assert_selector '.notice', text: 'Welcome! You have signed up successfully.'
    perform_enqueued_jobs
    assert User.last.banned?
  end
end
