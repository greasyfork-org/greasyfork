require 'application_system_test_case'

class PostInstallTest < ApplicationSystemTestCase
  test 'post install page with promoted script' do
    script = Script.find(2)
    promoted_script = Script.find(1)
    script.update!(promoted_script:)
    visit post_install_script_path(script, locale: :en)
    assert_content promoted_script.name
  end

  test 'post install page without promoted script' do
    script = Script.find(2)
    other_scripts = Script.find([1, 3])
    Script.any_instance.expects(:similar_scripts).returns(other_scripts)
    visit post_install_script_path(script, locale: :en)
    other_scripts.each do |other_script|
      assert_content other_script.name
    end
  end
end
