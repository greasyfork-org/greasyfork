require 'test_helper'

class ScriptCompatibilityTest < ActiveSupport::TestCase

	test 'simple' do
		script = get_valid_script
		sv = ScriptVersion.new
		sv.script = script
		sv.code = <<-EOF
// ==UserScript==
// @name		A Test!
// @description		Unit test.
// @version 1.1
// @namespace http://greasyfork.local/users/1
// @compatible firefox
// ==/UserScript==
var foo = 2;
		EOF
		sv.calculate_all
		script.apply_from_script_version(sv)
		assert_equal 1, script.compatibilities.length
		c = script.compatibilities.first
		assert_equal true, c.compatible
		assert_equal 'Firefox', c.browser.name
		assert_nil c.comments
		sv.save!
		script.save!
		assert_equal 1, Script.find(script.id).compatibilities.length
	end

	test 'multiple' do
		script = get_valid_script
		sv = ScriptVersion.new
		sv.script = script
		sv.code = <<-EOF
// ==UserScript==
// @name		A Test!
// @description		Unit test.
// @version 1.1
// @namespace http://greasyfork.local/users/1
// @compatible firefox
// @compatible chrome Except for X
// ==/UserScript==
var foo = 2;
		EOF
		sv.calculate_all
		script.apply_from_script_version(sv)
		assert_equal 2, script.compatibilities.length, script.compatibilities.inspect
		fx = script.compatibilities[0]
		ch = script.compatibilities[1]
		assert_equal true, fx.compatible
		assert_equal 'Firefox', fx.browser.name
		assert_nil fx.comments
		assert_equal true, ch.compatible
		assert_equal 'Chrome', ch.browser.name
		assert_equal 'Except for X', ch.comments
		sv.save!
		script.save!
		assert_equal 2, Script.find(script.id).compatibilities.length
	end

	test 'incompatible' do
		script = get_valid_script
		sv = ScriptVersion.new
		sv.script = script
		sv.code = <<-EOF
// ==UserScript==
// @name		A Test!
// @description		Unit test.
// @version 1.1
// @namespace http://greasyfork.local/users/1
// @incompatible firefox
// ==/UserScript==
var foo = 2;
		EOF
		sv.calculate_all
		script.apply_from_script_version(sv)
		assert_equal 1, script.compatibilities.length
		c = script.compatibilities.first
		assert_equal false, c.compatible
	end

	test 'with version' do
		script = get_valid_script
		sv = ScriptVersion.new
		sv.script = script
		sv.code = <<-EOF
// ==UserScript==
// @name		A Test!
// @description		Unit test.
// @version 1.1
// @namespace http://greasyfork.local/users/1
// @compatible firefox(24-27)
// ==/UserScript==
var foo = 2;
		EOF
		sv.calculate_all
		script.apply_from_script_version(sv)
		assert_equal 1, script.compatibilities.length
		c = script.compatibilities.first
		assert_equal true, c.compatible
		assert_equal 'Firefox', c.browser.name
		assert_nil c.comments
	end

	test 'unknown' do
		script = get_valid_script
		sv = ScriptVersion.new
		sv.script = script
		sv.code = <<-EOF
// ==UserScript==
// @name		A Test!
// @description		Unit test.
// @version 1.1
// @namespace http://greasyfork.local/users/1
// @compatible firefox
// @compatible crazybrowser
// ==/UserScript==
var foo = 2;
		EOF
		sv.calculate_all
		script.apply_from_script_version(sv)
		assert_equal 1, script.compatibilities.length
		c = script.compatibilities.first
		assert_equal true, c.compatible
		assert_equal 'Firefox', c.browser.name
		assert_nil c.comments
	end

end
