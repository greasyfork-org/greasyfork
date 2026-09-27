require 'test_helper'

class ScriptSetsHelperTest < ActionView::TestCase
  test 'returns calculated scripts' do
    scripts = [Script.new]
    script_set = mock
    script_set.expects(:scripts).with(:greasyfork).returns(scripts)
    stubs(:script_subset).returns(:greasyfork)

    assert_equal scripts, calculated_scripts_for_set(script_set)
  end

  test 'returns nil when script calculation times out' do
    script_set = mock
    script_set.expects(:scripts).with(:greasyfork).raises(Timeout::Error)
    stubs(:script_subset).returns(:greasyfork)

    assert_nil calculated_scripts_for_set(script_set)
  end
end
