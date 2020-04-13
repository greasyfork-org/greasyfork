require 'application_system_test_case'

class ShowTest < ApplicationSystemTestCase
  test 'all authors can see author links' do
    script = Script.find(2)
    assert_operator script.users.count, :>, 1
    script.users.each do |user|
      login_as(user, scope: :user)
      visit script_path(script, locale: :en)
      click_link 'Update'
    end
  end

  test 'all authors should be listed' do
    script = Script.find(2)
    visit script_path(script, locale: :en)
    script.users.each do |user|
      assert_selector 'a', text: user.name
    end
  end

  test 'deleted script not replaced' do
    script = Script.find(2)
    script.update!(script_delete_type_id: 1)
    assert_script_deleted_page do
      visit script_path(script, locale: :en)
    end
  end

  test 'deleted script replaced' do
    script = Script.find(2)
    replacing_script = Script.find(1)
    script.update!(script_delete_type_id: 1, replaced_by_script: replacing_script)
    visit script_path(script, locale: :en)
    assert_current_path script_path(replacing_script, locale: :en)
  end
end
