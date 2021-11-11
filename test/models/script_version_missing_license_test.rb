require 'test_helper'

class ScriptVersionMissingLicenseTest < ActiveSupport::TestCase
  CODE_WITHOUT_LICENSE = <<~JS.freeze
    // ==UserScript==
    // @name		A Test!
    // @description		Unit test.
    // @updateURL		http://example.com
    // @namespace		http://greasyfork.local/users/1
    // @include *
    // @version 1.1
    // ==/UserScript==
    foo.baz();
  JS

  test 'missing license on new' do
    sv = ScriptVersion.new
    sv.code = CODE_WITHOUT_LICENSE
    sv.version = '123'
    script = Script.new
    sv.script = script
    script.authors.build(user: User.find(1))
    sv.rewritten_code = sv.calculate_rewritten_code
    assert_not sv.valid?
    assert_equal ['warning-license_missing'], sv.errors.full_messages
    sv.license_missing_override = true
    assert sv.valid?, sv.errors.full_messages
    sv.calculate_all
    script.apply_from_script_version(sv)
    sv.save!
    assert script.missing_license_warned
  end

  test 'missing license on existing without missing_license_warned' do
    sv = ScriptVersion.new
    sv.code = CODE_WITHOUT_LICENSE
    sv.version = '123'
    sv.script = Script.find(1)
    sv.rewritten_code = sv.calculate_rewritten_code
    assert_not sv.valid?
    assert_equal ['warning-license_missing'], sv.errors.full_messages
    sv.license_missing_override = true
    assert sv.valid?, sv.errors.full_messages
    sv.save!
    assert sv.script.missing_license_warned
  end

  test 'missing license on existing with missing_license_warned' do
    sv = ScriptVersion.new
    sv.code = CODE_WITHOUT_LICENSE
    sv.version = '123'
    sv.script = Script.find(1)
    sv.script.missing_license_warned = true
    sv.rewritten_code = sv.calculate_rewritten_code
    assert sv.valid?, sv.errors.full_messages
  end
end
