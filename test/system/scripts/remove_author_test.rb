require 'application_system_test_case'

class RemoveAuthorTest < ApplicationSystemTestCase
  test 'no remove author UI on single authorship' do
    script = Script.find(1)
    login_as(script.users.first, scope: :user)
    visit admin_script_url(script, locale: :en)
    assert_no_selector('h4', text: 'Remove Authors')
  end

  test 'can remove author on multiple authorship' do
    script = scripts(:two)
    assert_equal 2, script.users.count
    login_as(script.users.first, scope: :user)
    visit admin_script_url(script, locale: :en)
    assert_selector('h4', text: 'Remove Authors')
    within '#user-remove-list li:last-child' do
      accept_prompt 'Are you sure you want to remove Geoffrey as an author?' do
        click_button 'Remove'
      end
    end
    assert_content 'Geoffrey has been removed as an author.'
    assert_equal 1, script.users.count
  end
end
