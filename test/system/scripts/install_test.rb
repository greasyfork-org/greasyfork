require 'application_system_test_case'

class InstallTest < ApplicationSystemTestCase
  test 'installing a script' do
    script = Script.find(2)
    visit script_url(script, locale: :en)
    assert_difference -> { Script.connection.select_value('select count(*) from daily_install_counts') } => 1 do
      click_link 'Install this script'
      assert_current_path '/scripts/2-mystring/code/MyString.user.js'
    end

    visit script_url(script, locale: :en)
    assert_no_difference -> { Script.connection.select_value('select count(*) from daily_install_counts') } do
      click_link 'Install this script'
      assert_current_path '/scripts/2-mystring/code/MyString.user.js'
    end
  end

  test 'installing a script with antifeatures' do
    script = Script.find(22)
    visit script_url(script, locale: :en)
    click_link 'Install this script'
    assert_content 'This script contains antifeatures'

    assert_difference -> { Script.connection.select_value('select count(*) from daily_install_counts') } => 1 do
      click_button 'Install script'
      assert_current_path '/scripts/22-a-test-with-antifeatures/code/A%20Test%20with%20antifeatures!.user.js'
    end
  end
end
