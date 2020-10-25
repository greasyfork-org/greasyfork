require 'application_system_test_case'

class DeleteTest < ApplicationSystemTestCase
  test 'script delete' do
    script = Script.find(1)
    login_as(script.users.first, scope: :user)
    visit delete_script_url(script, locale: :en)
    choose 'They will keep it as it is.'
    click_button 'Delete'
    assert_content 'Daily installs'
    assert script.reload.deleted?
    click_on 'Delete'
    click_button 'Undelete'
    assert_content 'Daily installs'
    assert_not script.reload.deleted?
  end
end
