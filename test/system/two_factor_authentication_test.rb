require 'application_system_test_case'

class TwoFactorAuthenticationTest < ApplicationSystemTestCase
  test 'enabling 2FA' do
    user = User.first
    user.password = user.password_confirmation = 'password'
    user.save!

    login_as(user)

    visit user_path(user, locale: :en)
    click_link 'Edit sign in methods'
    click_button 'Enable 2FA'

    User.any_instance.expects(:validate_and_consume_otp!).returns(true)
    fill_in 'code', with: '123456'
    click_button 'Verify code'

    assert_content '2FA has been enabled'
    assert user.reload.otp_required_for_login
  end

  test 'failing to enable 2FA' do
    user = User.first
    user.password = user.password_confirmation = 'password'
    user.save!

    login_as(user)

    visit user_path(user, locale: :en)
    click_link 'Edit sign in methods'
    click_button 'Enable 2FA'

    User.any_instance.expects(:validate_and_consume_otp!).returns(false)
    fill_in 'code', with: '123456'
    click_button 'Verify code'

    assert_content '2FA code is not correct. Please try again.'
    assert_not user.reload.otp_required_for_login
  end

  test 'disabling 2FA' do
    user = User.first
    user.password = user.password_confirmation = 'password'
    user.otp_secret = User.generate_otp_secret
    user.otp_required_for_login = true
    user.save!

    login_as(user)

    visit user_path(user, locale: :en)
    click_link 'Edit sign in methods'
    click_button 'Disable 2FA'
    assert_content '2FA has been disabled'

    assert_not user.reload.otp_required_for_login
  end

  test 'logging in with 2FA' do
    user = User.first
    user.password = 'password'
    user.otp_secret = User.generate_otp_secret
    user.otp_required_for_login = true
    user.save!

    visit new_user_session_path(locale: :en)
    fill_in 'Email', with: user.email
    fill_in 'Password', with: 'password'
    click_button 'Log in'

    # Still not signed in
    assert_no_link user.name
    assert_link 'Sign in'

    User.any_instance.expects(:validate_and_consume_otp!).returns(true)
    fill_in 'user[otp_attempt]', with: '123456'
    click_button 'Log in'

    assert_content 'Signed in successfully.'
  end

  test 'failure logging in with 2FA' do
    user = User.first
    user.password = 'password'
    user.otp_secret = User.generate_otp_secret
    user.otp_required_for_login = true
    user.save!

    visit new_user_session_path(locale: :en)
    fill_in 'Email', with: user.email
    fill_in 'Password', with: 'password'
    click_button 'Log in'

    # Still not signed in
    assert_no_link user.name
    assert_link 'Sign in'

    User.any_instance.expects(:validate_and_consume_otp!).returns(false)
    fill_in 'user[otp_attempt]', with: '123456'
    click_button 'Log in'

    assert_content 'Invalid Email or password'
  end
end
