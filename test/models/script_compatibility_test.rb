require 'test_helper'

class ScriptCompatibilityTest < ActiveSupport::TestCase
  test 'simple' do
    script = valid_script
    sv = ScriptVersion.new
    sv.script = script
    sv.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.1
      // @namespace http://greasyfork.local/users/1
      // @compatible firefox
      // @include *
      // ==/UserScript==
      var foo = 2;
    JS
    sv.calculate_all
    script.apply_from_script_version(sv)
    assert_equal 1, script.compatibilities.length
    c = script.compatibilities.first
    assert c.compatible
    assert_equal 'Firefox', c.browser.name
    assert_nil c.comments
    sv.save!
    script.save!
    assert_equal 1, Script.find(script.id).compatibilities.length
  end

  test 'multiple' do
    script = valid_script
    sv = ScriptVersion.new
    sv.script = script
    sv.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.1
      // @namespace http://greasyfork.local/users/1
      // @compatible firefox
      // @compatible chrome Except for X
      // @include *
      // ==/UserScript==
      var foo = 2;
    JS
    sv.calculate_all
    script.apply_from_script_version(sv)
    assert_equal 2, script.compatibilities.length, script.compatibilities.inspect
    fx = script.compatibilities[0]
    ch = script.compatibilities[1]
    assert fx.compatible
    assert_equal 'Firefox', fx.browser.name
    assert_nil fx.comments
    assert ch.compatible
    assert_equal 'Chrome', ch.browser.name
    assert_equal 'Except for X', ch.comments
    sv.save!
    script.save!
    assert_equal 2, Script.find(script.id).compatibilities.length
  end

  test 'incompatible' do
    script = valid_script
    sv = ScriptVersion.new
    sv.script = script
    sv.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.1
      // @namespace http://greasyfork.local/users/1
      // @incompatible firefox
      // @include *
      // ==/UserScript==
      var foo = 2;
    JS
    sv.calculate_all
    script.apply_from_script_version(sv)
    assert_equal 1, script.compatibilities.length
    c = script.compatibilities.first
    assert_not c.compatible
  end

  test 'with version' do
    script = valid_script
    sv = ScriptVersion.new
    sv.script = script
    sv.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.1
      // @namespace http://greasyfork.local/users/1
      // @compatible firefox(24-27)
      // @include *
      // ==/UserScript==
      var foo = 2;
    JS
    sv.calculate_all
    script.apply_from_script_version(sv)
    assert_equal 1, script.compatibilities.length
    c = script.compatibilities.first
    assert c.compatible
    assert_equal 'Firefox', c.browser.name
    assert_nil c.comments
  end

  test 'unknown' do
    script = valid_script
    sv = ScriptVersion.new
    sv.script = script
    sv.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.1
      // @namespace http://greasyfork.local/users/1
      // @compatible firefox
      // @compatible crazybrowser
      // @include *
      // ==/UserScript==
      var foo = 2;
    JS
    sv.calculate_all
    script.apply_from_script_version(sv)
    assert_equal 1, script.compatibilities.length
    c = script.compatibilities.first
    assert c.compatible
    assert_equal 'Firefox', c.browser.name
    assert_nil c.comments
  end
end
