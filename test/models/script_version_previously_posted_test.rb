require 'test_helper'

class ScriptVersionPreviouslyPostedTest < ActiveSupport::TestCase
  test 'posting previously posted code as update warns' do
    script = Script.find(3)
    assert script.valid? && script.script_versions.length == 1 && script.script_versions.first.valid?

    previous_script = Script.find(2)
    previous_code = <<~JS
      // ==UserScript==
      // @name		Some very unique code
      // @description		Unit test.
      // @version 1
      // @updateURL		http://example.com
      // @namespace		http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // ==/UserScript==
      very.unique = 'code'
    JS
    update_script_version_with_code(previous_script.newest_saved_script_version, previous_code)

    sv = ScriptVersion.new
    sv.code = previous_code
    sv.script = script
    sv.calculate_all
    sv.namespace_check_override = true
    sv.version_check_override = true
    sv.meta_not_at_start_confirmation = true
    assert_not sv.valid?
    assert_equal [previous_script], sv.previously_posted_scripts

    sv.allow_code_previously_posted = true
    assert sv.valid?, sv.errors.full_messages
  end

  test 'posting previously posted code on the same script is OK' do
    script = Script.find(3)
    assert script.valid? && script.script_versions.length == 1 && script.script_versions.first.valid?

    previous_code = <<~JS
      // ==UserScript==
      // @name		Some very unique code
      // @description		Unit test.
      // @version 1
      // @updateURL		http://example.com
      // @namespace		http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // ==/UserScript==
      very.unique = 'code'
    JS
    update_script_version_with_code(script.script_versions.first, previous_code)

    sv = ScriptVersion.new
    sv.code = previous_code
    sv.script = script
    sv.calculate_all
    sv.namespace_check_override = true
    sv.version_check_override = true
    sv.meta_not_at_start_confirmation = true
    assert sv.valid?
    assert_empty sv.previously_posted_scripts
  end

  test 'posting previously posted code on the same script and on another script is OK' do
    script = Script.find(3)
    assert script.valid? && script.script_versions.length == 1 && script.script_versions.first.valid?

    previous_code = <<~JS
      // ==UserScript==
      // @name		Some very unique code
      // @description		Unit test.
      // @version 1
      // @updateURL		http://example.com
      // @namespace		http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // ==/UserScript==
      very.unique = 'code'
    JS
    update_script_version_with_code(script.script_versions.first, previous_code)

    previous_script = Script.find(2)
    update_script_version_with_code(previous_script.newest_saved_script_version, previous_code)

    sv = ScriptVersion.new
    sv.code = previous_code
    sv.script = script
    sv.calculate_all
    sv.namespace_check_override = true
    sv.version_check_override = true
    sv.meta_not_at_start_confirmation = true
    assert sv.valid?
    assert_empty sv.previously_posted_scripts
  end

  private

  def update_script_version_with_code(sv, code)
    previous_script_code = ScriptCode.new
    previous_script_code.code = code
    previous_script_code.save!
    sv.script_code = previous_script_code
    sv.rewritten_script_code = previous_script_code
    sv.save!
  end
end
