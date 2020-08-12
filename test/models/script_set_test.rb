require 'test_helper'

class ScriptSetTest < ActiveSupport::TestCase
  test 'simple include' do
    set = ScriptSet.new
    script = Script.new
    set.add_child(script)
    assert_equal [script], set.scripts(:all).to_a
  end

  test 'nested include' do
    set1 = ScriptSet.new
    set2 = ScriptSet.new
    script = Script.new
    set1.add_child(set2)
    set2.add_child(script)
    assert_equal [script], set1.scripts(:all).to_a
  end

  test 'same script included twice' do
    set1 = ScriptSet.new
    set2 = ScriptSet.new
    script = Script.new
    set1.add_child(set2)
    set1.add_child(script)
    set2.add_child(script)
    assert_equal [script], set1.scripts(:all).to_a
  end

  test 'excluded script' do
    set1 = ScriptSet.new
    set2 = ScriptSet.new
    script1 = Script.new
    script2 = Script.new
    set1.add_child(set2)
    set1.add_child(script1, exclusion: true)
    set2.add_child(script1)
    set2.add_child(script2)
    assert_equal [script2], set1.scripts(:all).to_a
  end

  test 'excluded group' do
    set1 = ScriptSet.new
    set2 = ScriptSet.new
    set3 = ScriptSet.new
    script1 = Script.new
    script2 = Script.new
    script3 = Script.new
    set1.add_child(set2)
    set1.add_child(set3, exclusion: true)
    set2.add_child(script1)
    set2.add_child(script2)
    set3.add_child(script2)
    set3.add_child(script3)
    assert_equal [script1], set1.scripts(:all).to_a
  end

  test 'recursive' do
    set1 = ScriptSet.new
    set2 = ScriptSet.new
    script = Script.new
    set1.add_child(set2)
    set1.add_child(script)
    set2.add_child(set1)
    assert_equal [script], set1.scripts(:all).to_a
  end
end
