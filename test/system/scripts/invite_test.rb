require 'application_system_test_case'

class InviteTest < ApplicationSystemTestCase
  test 'bad invited user url' do
    script = Script.find(1)
    login_as(script.users.first, scope: :user)
    visit admin_script_url(script, locale: :en)
    fill_in 'User to invite', with: 'http://google.com'
    click_button 'Send invite'
    assert_selector 'p', text: 'Invited user URL is not valid.'
  end

  test "invited user url doesn't exist" do
    script = Script.find(1)
    login_as(script.users.first, scope: :user)
    visit admin_script_url(script, locale: :en)
    fill_in 'User to invite', with: 'https://greasyfork.org/users/12332232323-me'
    click_button 'Send invite'
    assert_selector 'p', text: 'Invited user URL is not valid.'
  end

  test 'invited user url is already author' do
    script = Script.find(1)
    login_as(script.users.first, scope: :user)
    visit admin_script_url(script, locale: :en)
    fill_in 'User to invite', with: "https://greasyfork.org/users/#{script.users.first.id}-me"
    click_button 'Send invite'
    assert_selector 'p', text: 'The user you specified is already an author of this script.'
  end

  test 'valid invite' do
    script = Script.find(1)
    login_as(script.users.first, scope: :user)
    user_to_invite = User.find(3)
    visit admin_script_url(script, locale: :en)
    fill_in 'User to invite', with: "https://greasyfork.org/users/#{user_to_invite.id}-me"
    click_button 'Send invite'
    assert_selector 'p', text: 'Invitation has been sent.'
    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
  end
end
