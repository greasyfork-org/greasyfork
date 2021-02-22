require 'application_system_test_case'

module Users
  class LoginTest < ::ApplicationSystemTestCase
    def log_in(user)
      user.update!(password: 'password')
      visit root_url
      click_link 'Sign in'
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'password'
      click_button 'Log in'
    end

    test 'can log in' do
      user = users(:one)
      log_in(user)
      assert_content 'Signed in successfully.'
    end

    test "can't log in when banned" do
      user = users(:one)
      user.update!(banned_at: Time.zone.now)
      log_in(user)
      assert_content 'Your account has been banned.'
    end

    test 'can see banned reason' do
      user = users(:one)
      user.update!(banned_at: Time.zone.now)
      ModeratorAction.create!(user: user, reason: 'You suck', action: 'ban', moderator: users(:admin))
      log_in(user)
      assert_content 'Your account has been banned. A moderator gave the following reason: "You suck".'
    end

    test 'can see banning report' do
      user = users(:one)
      user.update!(banned_at: Time.zone.now)
      report = Report.create!(reporter: users(:admin), item: user, reason: Report::REASON_ABUSE)
      ModeratorAction.create!(user: user, reason: 'You suck', action: 'ban', moderator: users(:admin), report: report)
      log_in(user)
      assert_content 'Your account has been banned in response to this report.'
    end

    test 'can delete account when banned' do
      with_sphinx do
        user = users(:one)
        user.update!(banned_at: Time.zone.now)
        log_in(user)
        assert_content 'Your account has been banned.'
        click_link 'delete your account'
        fill_in 'Email', with: user.email
        fill_in 'Password', with: 'password'
        assert_changes -> { User.find_by(id: user.id) }, to: nil do
          click_button 'Log in'
          assert_content 'Your account has been deleted.'
        end
      end
    end
  end
end
