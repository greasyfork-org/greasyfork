require 'application_system_test_case'

module Users
  class PasswordResetTest < ::ApplicationSystemTestCase
    include ActionMailer::TestHelper

    test 'resetting password' do
      user = users(:junior)
      assert_empty user.scripts
      user.update!(otp_required_for_login: false)
      reset_password(user)
      click_link 'Sign out'
      assert_content 'Signed out successfully.'
      click_link 'Sign in'
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'newpassword'
      click_button 'Log in'
      assert_content 'Signed in successfully.'
    end

    test '2fa can be bypassed by resetting password' do
      user = users(:one)
      user.update!(otp_required_for_login: true)
      reset_password(user)
      assert_link 'Sign out'
      # It's still required, but we're signed in.
      assert user.reload.otp_required_for_login
    end

    def reset_password(user)
      visit root_url
      click_on 'Sign in'
      click_on 'Forgot your password'
      fill_in 'Email', with: user.email

      assert_emails(1) do
        click_on 'Send me reset password instructions'
        assert_content 'If your email address exists in our database, you will receive a password recovery link at your email address in a few minutes.'
      end

      email = ActionMailer::Base.deliveries.last
      assert_not_nil email
      assert_equal [user.email], email.to
      reset_link = email.body.to_s.match(/http[^"]+/)[0]
      visit reset_link
      fill_in 'New password', with: 'newpassword'
      fill_in 'Confirm new password', with: 'newpassword'
      click_on 'Change my password'
      assert_content 'Your password has been changed successfully. You are now signed in.'
    end
  end
end
