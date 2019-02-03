require "application_system_test_case"

class ListTest < ApplicationSystemTestCase
  def around(&block)
    ThinkingSphinx::Test.init
    ThinkingSphinx::Test.start index: true
    ThinkingSphinx::Configuration.instance.settings['real_time_callbacks'] = true
    block.call
    ThinkingSphinx::Test.stop
    ThinkingSphinx::Test.clear
  end

  test "script list" do
    visit scripts_url
    assert_selector 'h2', text: 'MyString'
  end

  test 'libraries' do
    visit libraries_scripts_url
    assert_selector 'h2', text: 'jQuery'
  end
end
