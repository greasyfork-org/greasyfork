require 'application_system_test_case'

class AcceptInvitationUTest < ApplicationSystemTestCase
  test 'good invitation' do
    script = Script.find(1)
    invited_user = User.find(3)
    script.script_invitations.create!(invited_user: invited_user, expires_at: 1.day.from_now)
    login_as(invited_user)
    visit accept_invitation_script_path(script, locale: :en)
    assert_selector 'p', text: 'You are now an author on this script.'
    assert_includes(script.reload.users, invited_user)
  end

  test 'bad invitation' do
    script = Script.find(1)
    invited_user = User.find(3)
    script.script_invitations.create!(invited_user: invited_user, expires_at: 1.day.ago)
    login_as(invited_user)
    visit accept_invitation_script_path(script, locale: :en)
    assert_selector 'p', text: 'Invitation has expired.'
    assert_not_includes(script.reload.users, invited_user)
  end

  test 'not logged in' do
    script = Script.find(1)
    invited_user = User.find(3)
    script.script_invitations.create!(invited_user: invited_user, expires_at: 1.day.from_now)
    visit accept_invitation_script_path(script, locale: :en)
    assert_selector 'p', text: 'You need to sign in or sign up before continuing.'
  end
end
