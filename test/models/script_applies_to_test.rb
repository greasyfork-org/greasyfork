require 'test_helper'

class ScriptAppliesToTest < ActiveSupport::TestCase
  test 'deleting also deletes SiteApplication if not otherwise used' do
    script = scripts(:example_com_application)
    assert_equal 1, script.script_applies_tos.count
    assert_equal 1, SiteApplication.where(text: 'example.com').count
    assert_difference -> { SiteApplication.where(text: 'example.com').count }, -1 do
      assert_difference -> { ScriptAppliesTo.count }, -1 do
        script.destroy!
      end
    end
  end

  test "deleting retains SiteApplication if it's used elsewhere" do
    script = scripts(:example_com_application)

    other_script = scripts(:one)
    other_script.script_applies_tos.create!(site_application: SiteApplication.find_by(text: 'example.com'))

    assert_no_difference -> { SiteApplication.where(text: 'example.com').count } do
      assert_difference -> { ScriptAppliesTo.count }, -1 do
        script.destroy!
      end
    end
  end

  test 'domain and non-domain SiteApplications are treated separately' do
    script = scripts(:example_com_application)

    js = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @updateURL		http://example.com
      // @namespace		http://greasyfork.local/users/1
      // @match *://example.com/*
      // @license MIT
      // ==/UserScript==
      foo.baz();
    JS
    sv = ScriptVersion.new
    sv.code = js
    sv.version = '123'
    sv.script = script
    sv.rewritten_code = sv.calculate_rewritten_code
    script.apply_from_script_version(sv)
    script.save!

    assert_equal 1, script.script_applies_tos.count
    assert_equal 1, script.site_applications.count
    assert_equal 'example.com', script.site_applications.first.text
    assert_equal 'example.com', script.site_applications.first.domain_text
    assert script.site_applications.first.domain?

    js = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @updateURL		http://example.com
      // @namespace		http://greasyfork.local/users/1
      // @match example.com
      // @license MIT
      // ==/UserScript==
      foo.baz();
    JS
    sv = ScriptVersion.new
    sv.code = js
    sv.version = '123'
    sv.script = script
    sv.rewritten_code = sv.calculate_rewritten_code
    script.apply_from_script_version(sv)
    script.save!

    assert_equal 1, script.script_applies_tos.count
    assert_equal 1, script.site_applications.count
    assert_equal 'example.com', script.site_applications.first.text
    assert_nil script.site_applications.first.domain_text
    assert_not script.site_applications.first.domain?
  end

  test 'switching from .tld to .com' do
    script = scripts(:example_com_application)

    js = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @updateURL		http://example.com
      // @namespace		http://greasyfork.local/users/1
      // @match *://example.tld/*
      // @license MIT
      // ==/UserScript==
      foo.baz();
    JS
    sv = ScriptVersion.new
    sv.code = js
    sv.version = '123'
    sv.script = script
    sv.rewritten_code = sv.calculate_rewritten_code
    script.apply_from_script_version(sv)
    script.save!

    assert_equal 5, script.script_applies_tos.count
    assert_includes script.site_applications.map(&:text), 'example.com'
    assert_includes script.site_applications.map(&:text), 'example.net'
    assert_includes script.site_applications.map(&:domain_text), 'example.com'
    assert_includes script.site_applications.map(&:domain_text), 'example.net'
    assert script.site_applications.all?(&:domain?)
    assert_not script.script_applies_tos.find { |sat| sat.text == 'example.com' }.tld_extra
    assert script.script_applies_tos.select { |sat| sat.text != 'example.com' }.all?(&:tld_extra?)

    js = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @updateURL		http://example.com
      // @namespace		http://greasyfork.local/users/1
      // @match *://example.com/*
      // @license MIT
      // ==/UserScript==
      foo.baz();
    JS
    sv = ScriptVersion.new
    sv.code = js
    sv.version = '123'
    sv.script = script
    sv.rewritten_code = sv.calculate_rewritten_code
    script.apply_from_script_version(sv)
    script.save!

    assert_equal 1, script.script_applies_tos.count
    assert_equal 1, script.site_applications.count
    assert_equal 'example.com', script.site_applications.first.text
    assert_not script.script_applies_tos.first.tld_extra?
  end

  test 'switching from .com to .tld' do
    script = scripts(:example_com_application)

    js = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @updateURL		http://example.com
      // @namespace		http://greasyfork.local/users/1
      // @match *://example.com/*
      // @license MIT
      // ==/UserScript==
      foo.baz();
    JS
    sv = ScriptVersion.new
    sv.code = js
    sv.version = '123'
    sv.script = script
    sv.rewritten_code = sv.calculate_rewritten_code
    script.apply_from_script_version(sv)
    script.save!

    assert_equal 1, script.script_applies_tos.count
    assert_equal 1, script.site_applications.count
    assert_equal 'example.com', script.site_applications.first.text
    assert_not script.script_applies_tos.first.tld_extra?

    js = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @updateURL		http://example.com
      // @namespace		http://greasyfork.local/users/1
      // @match *://example.tld/*
      // @license MIT
      // ==/UserScript==
      foo.baz();
    JS
    sv = ScriptVersion.new
    sv.code = js
    sv.version = '123'
    sv.script = script
    sv.rewritten_code = sv.calculate_rewritten_code
    script.apply_from_script_version(sv)
    script.save!

    assert_equal 5, script.script_applies_tos.count
    assert_includes script.site_applications.map(&:text), 'example.com'
    assert_includes script.site_applications.map(&:text), 'example.net'
    assert_includes script.site_applications.map(&:domain_text), 'example.com'
    assert_includes script.site_applications.map(&:domain_text), 'example.net'
    assert_not script.script_applies_tos.find { |sat| sat.text == 'example.com' }.tld_extra
    assert script.script_applies_tos.select { |sat| sat.text != 'example.com' }.all?(&:tld_extra?)
  end

  test 'switching from .tld to .net' do
    script = scripts(:example_com_application)

    js = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @updateURL		http://example.com
      // @namespace		http://greasyfork.local/users/1
      // @match *://example.tld/*
      // @license MIT
      // ==/UserScript==
      foo.baz();
    JS
    sv = ScriptVersion.new
    sv.code = js
    sv.version = '123'
    sv.script = script
    sv.rewritten_code = sv.calculate_rewritten_code
    script.apply_from_script_version(sv)
    script.save!

    assert_equal 5, script.script_applies_tos.count
    assert_includes script.site_applications.map(&:text), 'example.com'
    assert_includes script.site_applications.map(&:text), 'example.net'
    assert_includes script.site_applications.map(&:domain_text), 'example.com'
    assert_includes script.site_applications.map(&:domain_text), 'example.net'
    assert script.site_applications.all?(&:domain?)
    assert_not script.script_applies_tos.find { |sat| sat.text == 'example.com' }.tld_extra
    assert script.script_applies_tos.select { |sat| sat.text != 'example.com' }.all?(&:tld_extra?)

    js = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @updateURL		http://example.com
      // @namespace		http://greasyfork.local/users/1
      // @match *://example.net/*
      // @license MIT
      // ==/UserScript==
      foo.baz();
    JS
    sv = ScriptVersion.new
    sv.code = js
    sv.version = '123'
    sv.script = script
    sv.rewritten_code = sv.calculate_rewritten_code
    script.apply_from_script_version(sv)
    script.save!

    assert_equal 1, script.script_applies_tos.count
    assert_equal 1, script.site_applications.count
    assert_equal 'example.net', script.site_applications.first.text
    assert_not script.script_applies_tos.first.tld_extra?
  end

  test 'switching from .net to .tld' do
    script = scripts(:example_com_application)

    js = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @updateURL		http://example.com
      // @namespace		http://greasyfork.local/users/1
      // @match *://example.net/*
      // @license MIT
      // ==/UserScript==
      foo.baz();
    JS
    sv = ScriptVersion.new
    sv.code = js
    sv.version = '123'
    sv.script = script
    sv.rewritten_code = sv.calculate_rewritten_code
    script.apply_from_script_version(sv)
    script.save!

    assert_equal 1, script.script_applies_tos.count
    assert_equal 1, script.site_applications.count
    assert_equal 'example.net', script.site_applications.first.text
    assert_not script.script_applies_tos.first.tld_extra?

    js = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @updateURL		http://example.com
      // @namespace		http://greasyfork.local/users/1
      // @match *://example.tld/*
      // @license MIT
      // ==/UserScript==
      foo.baz();
    JS
    sv = ScriptVersion.new
    sv.code = js
    sv.version = '123'
    sv.script = script
    sv.rewritten_code = sv.calculate_rewritten_code
    script.apply_from_script_version(sv)
    script.save!

    assert_equal 5, script.script_applies_tos.count
    assert_includes script.site_applications.map(&:text), 'example.com'
    assert_includes script.site_applications.map(&:text), 'example.net'
    assert_includes script.site_applications.map(&:domain_text), 'example.com'
    assert_includes script.site_applications.map(&:domain_text), 'example.net'
    assert_not script.script_applies_tos.find { |sat| sat.text == 'example.com' }.tld_extra
    assert script.script_applies_tos.select { |sat| sat.text != 'example.com' }.all?(&:tld_extra?)
  end
end
