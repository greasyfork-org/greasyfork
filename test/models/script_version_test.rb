require 'test_helper'

class ScriptVersionTest < ActiveSupport::TestCase
  test 'calculate rewritten' do
    js = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @updateURL		http://example.com
      // @namespace		http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // ==/UserScript==
      foo.baz();
    JS
    sv = ScriptVersion.new
    sv.code = js
    sv.version = '123'
    sv.script = Script.find(1)
    sv.rewritten_code = sv.calculate_rewritten_code
    sv.save!
    expected_js = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @namespace		http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // @version 123
      // ==/UserScript==
      foo.baz();
    JS
    assert_equal expected_js, sv.rewritten_code
  end

  test 'calculate rewritten no meta' do
    js = <<~JS
      foo.baz();
    JS
    script = Script.new
    script.authors.build(user: User.find(1))
    sv = ScriptVersion.new
    sv.script = script
    sv.code = js
    sv.version = '123'
    assert_nil sv.calculate_rewritten_code
  end

  test 'calculate rewritten meta not at top' do
    script = Script.find(12)
    expected_js = <<~JS
      /* License info is here */
      // ==UserScript==
      // @name		A Test!
      // @namespace		http://example.com/1
      // @description		Unit test.
      // @version		1
      // @include *
      // @license MIT
      // ==/UserScript==
      foo.baz();
    JS
    assert_equal expected_js, script.script_versions.first.calculate_rewritten_code
  end

  test 'validate require exemption' do
    script = valid_script
    script_version = script.script_versions.first
    script_version.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @require		http://ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js
      // @include *
      // @license MIT
      // ==/UserScript==
      var foo = "bar";
    JS
    assert script_version.valid?, script_version.errors.full_messages.to_s
  end

  test 'syntax errors in code' do
    script = valid_script
    script.authors.clear
    script.authors.build(user: User.find(1))
    script_version = script.script_versions.first
    script_version.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // ==/UserScript==
      syn tax error
    JS
    assert_not script_version.valid?
    assert_not_empty script_version.errors[:code]
  end

  test 'JSON is not valid' do
    script = valid_script
    script.authors.clear
    script.authors.build(user: User.find(1))
    script_version = script.script_versions.first
    script_version.code = <<~JS
      {
        "this": "is json"
      }
    JS
    assert_not script_version.valid?
    assert_not_empty script_version.errors[:code]
  end

  test 'JSON is valid for libraries' do
    js = <<~JS
      {
        "this": "is json"
      }
    JS
    sv = ScriptVersion.new
    sv.code = js
    script = Script.find(13)
    script.script_type = 3
    sv.script = script
    sv.calculate_all(script.description)
    script.apply_from_script_version(sv)
    assert sv.valid?, sv.errors[:code]
  end

  test 'non-code is invalid for libraries' do
    sv = ScriptVersion.new
    sv.code = 'this is just words and not script'
    script = Script.find(13)
    script.script_type = 3
    sv.script = script
    sv.calculate_all(script.description)
    script.apply_from_script_version(sv)
    assert_not sv.valid?
  end

  test 'update code with changing version' do
    script = Script.find(3)
    assert(script.valid?) && (script.script_versions.length == 1) && script.script_versions.first.valid?
    sv = ScriptVersion.new
    sv.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.2
      // @namespace http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // ==/UserScript==
      var foo = 2;
    JS
    sv.script = script
    sv.calculate_all
    assert sv.valid?, sv.errors.full_messages.join(' ')
    assert_equal '1.2', sv.version
  end

  test 'update code without changing version' do
    script = Script.find(3)
    assert(script.valid?) && (script.script_versions.length == 1) && script.script_versions.first.valid?
    sv = ScriptVersion.new
    sv.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.1
      // @namespace http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // ==/UserScript==
      var foo = 2;
    JS
    sv.script = script
    sv.calculate_all
    assert_not sv.valid?
    assert_equal 1, sv.errors.to_a.length
  end

  test 'update code without changing version with override' do
    script = Script.find(3)
    assert(script.valid?) && (script.script_versions.length == 1) && script.script_versions.first.valid?
    sv = ScriptVersion.new
    sv.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.1
      // @namespace http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // ==/UserScript==
      var foo = 2;
    JS
    sv.script = script
    sv.calculate_all
    sv.version_check_override = true
    assert sv.valid?, sv.errors.full_messages.join(' ')
    assert_equal '1.1', sv.version
  end

  test 'update code without changing version with be_lenient' do
    script = Script.find(3)
    assert(script.valid?) && (script.script_versions.length == 1) && script.script_versions.first.valid?
    sv = ScriptVersion.new
    sv.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.1
      // @namespace http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // ==/UserScript==
      var foo = 2;
    JS
    sv.script = script
    sv.calculate_all
    sv.do_lenient_saving
    assert sv.valid?, sv.errors.full_messages.join(' ')
  end

  test 'missing version' do
    script = Script.new
    script.authors.build(user: User.find(1))
    sv = ScriptVersion.new
    sv.script = script
    # valid with the version
    sv.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.1
      // @namespace http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // ==/UserScript==
      var foo = 2;
    JS
    sv.calculate_all
    assert sv.valid?, sv.errors.full_messages.join(' ')
    # invalid without
    sv.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @namespace http://greasyfork.local/users/1
      // @license MIT
      // ==/UserScript==
      var foo = 2;
    JS
    sv.calculate_all
    assert_not sv.valid?, sv.errors.full_messages.join(' ')
  end

  test 'add missing version' do
    script = Script.new
    script.authors.build(user: User.find(1))
    sv = ScriptVersion.new
    sv.script = script
    # valid with the version
    sv.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.1
      // @namespace http://greasyfork.local/users/1/
      // @include *
      // @license MIT
      // ==/UserScript==
      var foo = 2000;
    JS
    sv.calculate_all
    assert sv.valid?, sv.errors.full_messages.join(' ')
    # invalid without
    sv.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @namespace http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // ==/UserScript==
      var foo = 2000;
    JS
    sv.add_missing_version = true
    sv.calculate_all
    assert sv.valid?
    assert_includes(sv.version, '0.0.1.20')
  end

  test 'update code without version previous had generated version' do
    script = Script.find(4)
    assert(script.valid?) && (script.script_versions.length == 1) && script.script_versions.first.valid?
    old_version = script.script_versions.first.version
    sv = ScriptVersion.new
    sv.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @namespace http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // ==/UserScript==
      var foo = 100;
    JS
    sv.script = script
    sv.calculate_all
    assert sv.valid?, sv.errors.full_messages.join(' ')
    assert(/^0\.0\.1\.[0-9]{14}$/ =~ sv.version)
    assert_not_equal sv.version, old_version
  end

  test 'update code without version previous had explicit version' do
    script = Script.find(5)
    assert(script.valid?) && (script.script_versions.length == 1) && script.script_versions.first.valid?
    sv = ScriptVersion.new
    sv.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @namespace http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // ==/UserScript==
        var foo = 2;
    JS
    sv.script = script
    sv.calculate_all
    assert_not sv.valid?
    assert_equal 1, sv.errors.to_a.length, sv.errors.to_a.inspect
  end

  test 'missing namespace' do
    script = Script.new
    script.authors.build(user: User.find(1))
    sv = ScriptVersion.new
    sv.script = script
    # valid with the namespace
    sv.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.1
      // @namespace http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // ==/UserScript==
      var foo = 2;
    JS
    sv.calculate_all
    assert sv.valid?, sv.errors.full_messages.join(' ')
    # invalid without
    sv.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.1
      // @include *
      // @license MIT
      // ==/UserScript==
      var foo = 2;
    JS
    sv.calculate_all
    assert_not sv.valid?
  end

  test 'add missing namespace' do
    script = Script.new
    script.authors.build(user: User.find(1))
    sv = ScriptVersion.new
    sv.script = script
    sv.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.1
      // @include *
      // @license MIT
      // ==/UserScript==
      var foo = 2;
    JS
    sv.calculate_all
    assert_not sv.valid?
    sv.add_missing_namespace = true
    sv.calculate_all
    expected = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.1
      // @include *
      // @license MIT
      // @namespace http://localhost/users/1
      // ==/UserScript==
      var foo = 2;
    JS
    assert_equal expected, sv.rewritten_code
    assert sv.valid?, sv.errors.full_messages.inspect
  end

  test 'add missing namespace based on previous version' do
    script = Script.find(6)
    sv = ScriptVersion.new
    sv.script = script
    sv.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.2
      // @include *
      // @license MIT
      // ==/UserScript==
      var foo = 2;
    JS
    sv.calculate_all
    assert sv.valid?, sv.errors.full_messages.inspect
    expected = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.2
      // @include *
      // @license MIT
      // @namespace http://example.com
      // ==/UserScript==
      var foo = 2;
    JS
    assert_equal expected, sv.rewritten_code
  end

  test 'retain namespace' do
    script = Script.find(6)
    sv = ScriptVersion.new
    sv.script = script
    sv.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.2
      // @namespace http://example.com
      // @include *
      // @license MIT
      // ==/UserScript==
        var foo = 2;
    JS
    sv.calculate_all
    expected = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.2
      // @namespace http://example.com
      // @include *
      // @license MIT
      // ==/UserScript==
        var foo = 2;
    JS
    assert_equal expected, sv.rewritten_code
    assert sv.valid?, sv.errors.full_messages.inspect
  end

  test 'change namespace' do
    script = Script.find(6)
    sv = ScriptVersion.new
    sv.script = script
    sv.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.2
      // @namespace http://example.com/1
      // @include *
      // @license MIT
      // ==/UserScript==
        var foo = 2;
    JS
    sv.calculate_all
    assert_not sv.valid?
  end

  test 'change namespace with override' do
    script = Script.find(6)
    sv = ScriptVersion.new
    sv.script = script
    sv.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.2
      // @namespace http://example.com/1
      // @include *
      // @license MIT
      // ==/UserScript==
      var foo = 2;
    JS
    sv.namespace_check_override = true
    sv.calculate_all
    expected = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.2
      // @namespace http://example.com/1
      // @include *
      // @license MIT
      // ==/UserScript==
      var foo = 2;
    JS
    assert_equal expected, sv.rewritten_code
    assert sv.valid?
  end

  test 'missing description' do
    js = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @namespace		http://example.com/1
      // @version		1
      // @license MIT
      // ==/UserScript==
      foo.baz();
    JS
    sv = ScriptVersion.new
    sv.code = js
    script = Script.new
    sv.script = script
    sv.calculate_all(script.description)
    script.apply_from_script_version(sv)
    assert_nil script.description
    assert_not script.valid?
  end

  test 'missing description previous had description' do
    js = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @namespace		http://example.com/1
      // @version		1
      // @include *
      // @license MIT
      // ==/UserScript==
      foo.baz();
    JS
    sv = ScriptVersion.new
    sv.code = js
    script = Script.find(11)
    sv.script = script
    sv.calculate_all(script.description)
    script.apply_from_script_version(sv)
    assert_equal 'Unit test.', script.description
    assert script.valid?
  end

  test 'missing name previous had name' do
    js = <<~JS
      // ==UserScript==
      // @description		A Test!
      // @namespace		http://example.com/1
      // @version		1
      // @include *
      // @license MIT
      // ==/UserScript==
      foo.baz();
    JS
    sv = ScriptVersion.new
    sv.code = js
    script = Script.find(13)
    sv.script = script
    sv.calculate_all(script.description)
    script.apply_from_script_version(sv)
    assert_nil script.name
    assert_not script.valid?
  end

  test 'library missing name previous had name' do
    js = <<~JS
      // ==UserScript==
      // @description		A Test!
      // @namespace		http://example.com/1
      // @version		1
      // @include *
      // @license MIT
      // ==/UserScript==
      foo.baz();
    JS
    sv = ScriptVersion.new
    sv.code = js
    script = Script.find(13)
    script.script_type = 3
    sv.script = script
    sv.calculate_all(script.description)
    script.apply_from_script_version(sv)
    assert_equal 'MyString', script.name
    assert script.valid?, script.errors.full_messages
  end

  test 'linebreak only update code without changing version' do
    script = Script.find(3)
    assert script.valid? && script.script_versions.length == 1 && script.script_versions.first.valid?
    sv = ScriptVersion.new
    sv.code = script.script_versions.first.code.gsub("\n", "\r\n")
    sv.script = script
    sv.calculate_all
    sv.allow_code_previously_posted = true
    assert sv.valid?
  end

  test 'get blanked code' do
    js = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 2
      // @namespace whatever
      // @require http://www.example.com/script.js
      // @require http://www.example.com/script2.js
      // @include *
      // @license MIT
      // ==/UserScript==
      var foo = "bar";
    JS
    sv = ScriptVersion.new
    sv.code = js
    sv.script = Script.new
    sv.calculate_all
    expected_meta = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		This script was deleted from Greasy Fork, and due to its negative effects, it has been automatically removed from your browser.
      // @version 2.0.0.1
      // @namespace whatever
      // @include *
      // @license MIT
      // ==/UserScript==
    JS
    assert_equal expected_meta, sv.generate_blanked_code
  end

  test 'get next version' do
    assert_equal '1.0.0.1', ScriptVersion.get_next_version('1')
    assert_equal '1.0.0.2', ScriptVersion.get_next_version('1.0.0.1')
    assert_equal '1.1.1.2', ScriptVersion.get_next_version('1.1.1.1')
    assert_equal '1.1.1.1b2a', ScriptVersion.get_next_version('1.1.1.1b1a')
  end

  test 'minified' do
    js = <<~JS
      // ==UserScript==
      // @name Test
      // @description		A Test!
      // @namespace		http://example.com/1
      // @version		1
      // @include *
      // @license MIT
      // ==/UserScript==
      var foo = 1;
    JS
    sv = ScriptVersion.new
    sv.code = js
    script = Script.new
    script.authors.build(user: User.first)
    sv.script = script
    script.script_versions << sv
    sv.calculate_all(script.description)
    script.apply_from_script_version(sv)
    # regular new script...
    assert sv.valid?, sv.errors.full_messages
    # now minified
    sv.code += 'function a(){}' * 5000
    assert_not sv.valid?
    # override
    sv.minified_confirmation = true
    assert sv.valid?
    # now an update
    sv.minified_confirmation = false
    script.save
    assert_not sv.valid?
  end

  test 'use same script code between code and rewritten' do
    js = <<~JS
      // ==UserScript==
      // @name Test
      // @description		A Test!
      // @namespace		http://example.com/1
      // @version		1
      // @include *
      // @license MIT
      // ==/UserScript==
      var foo = 1;
    JS
    sv = ScriptVersion.new
    sv.code = js
    script = Script.new
    script.authors.build(user: User.first)
    script.script_versions << sv
    sv.script = script
    sv.calculate_all(script.description)
    script.apply_from_script_version(sv)
    assert sv.valid?, sv.errors.full_messages
    script.save!
    sv.save!
    # code and rewritten code should be the same object
    assert_not_nil sv.script_code_id
    assert_not_nil sv.rewritten_script_code_id
    assert_equal sv.code, sv.rewritten_code
    assert_equal sv.script_code_id, sv.rewritten_script_code_id
    # new version, code changed, code and rewritten should have the same ids
    sv_new = ScriptVersion.new
    sv_new.script = script
    js = <<~JS
      // ==UserScript==
      // @name Test
      // @description		A Test!
      // @namespace		http://example.com/1
      // @version		2
      // @include *
      // @license MIT
      // ==/UserScript==
      var foo = 'bar';
    JS
    sv_new.code = js
    assert_not_equal sv_new.code, sv_new.rewritten_code
    sv_new.calculate_all(script.description)
    assert_equal sv_new.code, sv_new.rewritten_code
    script.save!
    sv_new.save!
    assert_equal sv_new.code, sv_new.rewritten_code
    assert_equal sv_new.script_code_id, sv_new.rewritten_script_code_id
    assert_not_equal sv_new.script_code_id, sv.rewritten_script_code_id
    # now test a case where code and rewritten should stay different
    js = <<~JS
      // ==UserScript==
      // @name Test
      // @description		A Test!
      // @namespace		http://example.com/1
      // @version		3
      // @downloadURL http://example.com
      // @include *
      // @license MIT
      // ==/UserScript==
      var foo = 'bar';
    JS
    sv_new2 = ScriptVersion.new
    sv_new2.script = script
    sv_new2.code = js
    assert_not_equal sv_new2.code, sv_new2.rewritten_code
    sv_new2.calculate_all(script.description)
    script.save!
    sv_new2.save!
    assert_not_equal sv_new2.code, sv_new2.rewritten_code
    assert_not_equal sv_new2.script_code_id, sv_new2.rewritten_script_code_id
  end

  test 'reuse script code when not changed' do
    js = <<~JS
      // ==UserScript==
      // @name Test
      // @description		A Test!
      // @namespace		http://example.com/1
      // @version		1
      // @include *
      // @license MIT
      // ==/UserScript==
      var foo = 1;
    JS
    sv = ScriptVersion.new
    sv.do_lenient_saving
    sv.code = js
    script = Script.new
    script.authors.build(user: User.first)
    sv.script = script
    script.script_versions << sv
    sv.calculate_all(script.description)
    script.apply_from_script_version(sv)
    assert sv.valid?, sv.errors.full_messages
    script.save!
    sv.save!
    previous_script_code_id = sv.script_code_id
    previous_rewritten_script_code_id = sv.rewritten_script_code_id
    script.reload
    assert_not_nil script.newest_saved_script_version
    # a new version with the same code
    sv = ScriptVersion.new
    sv.code = js
    sv.script = script
    sv.calculate_all(script.description)
    script.apply_from_script_version(sv)
    assert sv.valid?, sv.errors.full_messages
    script.save!
    sv.save!
    assert_equal previous_script_code_id, sv.script_code_id
    assert_equal previous_rewritten_script_code_id, sv.rewritten_script_code_id
    script.reload
    # a new version with a different code, but same rewritten code
    sv = ScriptVersion.new
    sv.do_lenient_saving
    js = <<~JS
      // ==UserScript==
      // @name Test
      // @description		A Test!
      // @namespace		http://example.com/1
      // @version		1
      // @downloadURL http://example.com
      // @include *
      // @license MIT
      // ==/UserScript==
      var foo = 1;
    JS
    sv.code = js
    sv.script = script
    sv.calculate_all(script.description)
    script.apply_from_script_version(sv)
    assert sv.valid?, sv.errors.full_messages
    script.save!
    sv.save!
    assert_not_equal previous_script_code_id, sv.script_code_id
    previous_script_code_id = sv.script_code_id
    assert_equal previous_rewritten_script_code_id, sv.rewritten_script_code_id
    script.reload
    # completely different code, with rewrites
    sv = ScriptVersion.new
    sv.do_lenient_saving
    js = <<~JS
      // ==UserScript==
      // @name Test
      // @description		A Test!
      // @namespace		http://example.com/1
      // @version		1
      // @downloadURL http://example.com
      // @include *
      // @license MIT
      // ==/UserScript==
      var foo = 2;
    JS
    sv.code = js
    sv.script = script
    sv.calculate_all(script.description)
    script.apply_from_script_version(sv)
    assert sv.valid?, sv.errors.full_messages
    script.save!
    sv.save!
    assert_not_equal previous_script_code_id, sv.script_code_id
    assert_not_equal previous_rewritten_script_code_id, sv.rewritten_script_code_id
    previous_script_code_id = sv.script_code_id
    previous_rewritten_script_code_id = sv.rewritten_script_code_id
    script.reload
    # rewritten stays the same, original changes to match
    sv = ScriptVersion.new
    sv.do_lenient_saving
    js = <<~JS
      // ==UserScript==
      // @name Test
      // @description		A Test!
      // @namespace		http://example.com/1
      // @version		1
      // @include *
      // @license MIT
      // ==/UserScript==
      var foo = 2;
    JS
    sv.code = js
    sv.script = script
    sv.calculate_all(script.description)
    script.apply_from_script_version(sv)
    assert sv.valid?, sv.errors.full_messages
    script.save!
    sv.save!
    assert_not_equal previous_script_code_id, sv.script_code_id
    assert_equal previous_rewritten_script_code_id, sv.rewritten_script_code_id
    assert_equal sv.script_code_id, sv.rewritten_script_code_id
  end

  test 'description truncate' do
    js = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		#{'1' * 600}
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include *
      // ==/UserScript==
      foo.baz();
    JS
    sv = ScriptVersion.new
    script = Script.new
    script.authors.build(user: User.first)
    sv.script = script
    sv.code = js
    sv.calculate_all
    script.apply_from_script_version(sv)
    assert_operator script.description.length, :>, 500
    assert_not script.valid?
    assert_equal(1, script.errors.to_a.length, script.errors.full_messages)
    assert_includes script.errors.full_messages.first, '@description', script.errors.full_messages
    sv.do_lenient_saving
    sv.calculate_all
    script.apply_from_script_version(sv)
    assert script.valid?, script.errors.full_messages
    assert_equal 500, script.description.length
  end

  test 'update retain additional info sync' do
    script = Script.find(14)
    assert script.valid?, script.errors.full_messages
    assert_equal 1, script.script_versions.length
    assert script.script_versions.first.valid?, script.script_versions.first.errors.full_messages
    assert script.localized_attributes_for('additional_info').all? { |la| !la.sync_identifier.nil? }, script.localized_attributes_for('additional_info').inspect

    sv = ScriptVersion.new
    sv.script = script
    sv.code = script.script_versions.first.code
    sv.rewritten_code = script.script_versions.first.rewritten_code
    sv.localized_attributes.build({ attribute_key: 'additional_info', attribute_value: 'New', attribute_default: true, locale: script.locale, value_markup: 'html' })
    sv.localized_attributes.build({ attribute_key: 'additional_info', attribute_value: 'Nouveau', attribute_default: false, locale: Locale.where(code: 'fr').first, value_markup: 'html' })
    sv.calculate_all
    assert sv.valid?, sv.errors.full_messages
    script.apply_from_script_version(sv)
    assert script.valid?, script.errors.full_messages

    assert_equal 2, script.localized_attributes_for('additional_info').length, script.localized_attributes_for('additional_info')
    # new values should be applied...
    assert %w[New Nouveau].all? { |ai| script.localized_attributes_for('additional_info').any? { |la| la.attribute_value == ai } }, script.localized_attributes_for('additional_info').inspect
    # but sync stuff should be retained!
    assert script.localized_attributes_for('additional_info').all? { |la| !la.sync_identifier.nil? }, script.localized_attributes_for('additional_info').inspect
  end

  test 'validate missing include' do
    script = valid_script
    script_version = script.script_versions.first
    script_version.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @license MIT
      // ==/UserScript==
      var foo = "bar";
    JS
    assert_not script_version.valid?
    assert_equal 1, script_version.errors.size
    assert_equal :code, script_version.errors.first.attribute
    assert_equal 'must include at least one @match or @include key', script_version.errors.first.message
  end

  test 'invalid meta' do
    script = valid_script
    script_version = script.script_versions.first
    script_version.code = <<~JS
      // ==UserScript==
      //@name		A Test!
      // @description		Unit test.
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include example.com
      // @license MIT
      // ==/UserScript==
      var foo = "bar";
    JS
    assert_not script_version.valid?
    assert_equal 1, script_version.errors.size
    assert_equal :code, script_version.errors.first.attribute
    assert_equal 'has an invalid meta directive. The proper format is // @foo', script_version.errors.first.message
  end

  test 'no code' do
    script = valid_script
    script_version = script.script_versions.first
    script_version.code = <<~JS
      // ==UserScript==
      // @name		blah blah
      // @description		description
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // ==/UserScript==
    JS
    assert_not script_version.valid?
    assert_equal :code, script_version.errors.first.attribute
    assert_equal 'contains no executable code', script_version.errors.first.message
  end

  test 'creation resets consecutive bad reviews' do
    script = Script.find(3)
    script.update(consecutive_bad_ratings_at: Time.current)
    assert script.valid? && script.script_versions.length == 1 && script.script_versions.first.valid?
    sv = ScriptVersion.new
    sv.code = script.script_versions.first.code
    sv.script = script
    sv.calculate_all
    sv.allow_code_previously_posted = true
    sv.save!
    assert_nil script.reload.consecutive_bad_ratings_at
  end

  test 'meta not at start' do
    script = valid_script
    script_version = script.script_versions.first
    script_version.code = <<~JS
      /* My license is here */
      // ==UserScript==
      // @name		blah blah
      // @description		description
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // ==/UserScript==
      let foo = 1
    JS
    assert_not script_version.valid?
    assert_equal :base, script_version.errors.first.attribute
    assert_equal 'warning-meta_not_at_start', script_version.errors.first.type
  end

  test 'syntax error with non-Latin encoding' do
    script = valid_script
    script_version = script.script_versions.first
    script_version.code = <<~JS
      // ==UserScript==
      // @name		blah blah
      // @description		description
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // ==/UserScript==

      var test = "[CENTER]Пользователь форума будет наказан по пункту правил пользования форумом:[QUOTE][SIZE=5][color=red]2.06.[/color] Запрещено размещение любого возрастного контента, которые несут в себе интимный, либо насильственный характер, также фотографии содержащие в себе "шок-контент", на примере расчленения и тому подобного.[/QUOTE][/CENTER]<br>"
    JS
    assert_not script_version.valid?
    assert_equal :code, script_version.errors.first.attribute
    assert_equal "contains errors: Uncaught SyntaxError: Unexpected identifier 'шок' at <eval>:11:278", script_version.errors.first.message
  end
end
