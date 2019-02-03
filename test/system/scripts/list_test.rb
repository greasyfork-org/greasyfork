require "application_system_test_case"

class ListTest < ApplicationSystemTestCase
  test "script list" do
    ThinkingSphinx::Test.init
    ThinkingSphinx::Test.start index: true
    ThinkingSphinx::Configuration.instance.settings['real_time_callbacks'] = true
    visit scripts_url
    assert_selector 'h2', text: 'MyString'
    ThinkingSphinx::Test.stop
    ThinkingSphinx::Test.clear
  end
end
