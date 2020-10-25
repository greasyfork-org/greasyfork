require 'application_system_test_case'

class ListTest < ApplicationSystemTestCase
  def around(&block)
    with_sphinx(&block)
  end

  test 'script list' do
    visit scripts_url
    assert_selector 'h2', text: 'MyString'
  end

  test 'libraries' do
    visit libraries_scripts_url
    assert_selector 'h2', text: 'jQuery'
  end

  test 'all authors should be listed' do
    visit scripts_url
    script = Script.find(2)
    assert_operator script.users.count, :>, 1
    within "li[data-script-id=\"#{script.id}\"]" do
      script.users.each do |user|
        assert_selector 'a', text: user.name
      end
    end
  end
end
