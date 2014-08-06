require 'test_helper'

class ScriptVersionTest < ActiveSupport::TestCase

	test 'get meta block' do
		js = <<END
// ==UserScript==
// @name		A Test!
// @description		Unit test.
// ==/UserScript==
var foo = "bar";
END
		meta_block = ScriptVersion.get_meta_block(js)
		expected_meta = <<END
// ==UserScript==
// @name		A Test!
// @description		Unit test.
// ==/UserScript==
END
		assert_equal expected_meta, meta_block
	end

	test 'get meta block no meta' do
		js = <<END
var foo = "bar";
END
		meta_block = ScriptVersion.get_meta_block(js)
		assert_nil meta_block
	end

	test 'parse meta' do
		js = <<END
// ==UserScript==
// @name		A Test!
// @description		Unit test.
// ==/UserScript==
var foo = "bar";
END
		meta = ScriptVersion.parse_meta(js)
		assert_not_nil meta
		assert_equal 1, meta['name'].length
		assert_equal 'A Test!', meta['name'].first
		assert_equal 1, meta['description'].length
		assert_equal 'Unit test.', meta['description'].first
	end

	test 'parse meta with no meta' do
		js = <<END
var foo = "bar";
END
		meta = ScriptVersion.parse_meta(js)
		assert_empty meta
	end

	test 'get code block' do
		js = <<END
// ==UserScript==
// @name		A Test!
// @description		Unit test.
// @version 1.0
// @namespace http://greasyfork.local/users/1
// ==/UserScript==
var foo = 'bar';
foo.baz();
END
		assert_equal ['', "\nvar foo = 'bar';\nfoo.baz();\n"], ScriptVersion.get_code_blocks(js)
	end

	test 'get code block meta not at top' do
		js = <<END
var foo = 'bar';
// ==UserScript==
// @name		A Test!
// @description		Unit test.
// @version 1.0
// @namespace http://greasyfork.local/users/1
// ==/UserScript==
foo.baz();
END
		assert_equal ["var foo = 'bar';\n", "\nfoo.baz();\n"], ScriptVersion.get_code_blocks(js)
	end

	test 'get code block with no meta' do
		js = <<END
var foo = 'bar';
foo.baz();
END
		assert_equal ["var foo = 'bar';\nfoo.baz();\n", ""], ScriptVersion.get_code_blocks(js)
	end

	test 'inject meta replace' do
		js = <<END
// ==UserScript==
// @name		A Test!
// @description		Unit test.
// @version 1.0
// @namespace http://greasyfork.local/users/1
// ==/UserScript==
foo.baz();
END
		sv = ScriptVersion.new
		sv.code = js
		rewritten_js = sv.inject_meta({:name => 'Something else'})
		expected_js = "// ==UserScript==\n// @name		Something else\n// @description		Unit test.\n// @version 1.0\n// @namespace http://greasyfork.local/users/1\n// ==/UserScript==\nfoo.baz();\n"
		assert_equal expected_js, rewritten_js
	end

	test 'inject meta remove' do
		js = <<END
// ==UserScript==
// @name		A Test!
// @description		Unit test.
// @version 1.0
// @namespace http://greasyfork.local/users/1
// ==/UserScript==
foo.baz();
END
		sv = ScriptVersion.new
		sv.code = js
		rewritten_js = sv.inject_meta({:name => nil})
		expected_js = "// ==UserScript==\n// @description		Unit test.\n// @version 1.0\n// @namespace http://greasyfork.local/users/1\n// ==/UserScript==\nfoo.baz();\n"
		assert_equal expected_js, rewritten_js
	end

	test 'inject meta remove not present' do
		js = <<END
// ==UserScript==
// @name		A Test!
// @description		Unit test.
// @version 1.0
// @namespace http://greasyfork.local/users/1
// ==/UserScript==
foo.baz();
END
		sv = ScriptVersion.new
		sv.code = js
		expected_js = "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n// @version 1.0\n// @namespace http://greasyfork.local/users/1\n// ==/UserScript==\nfoo.baz();\n"
		assert_equal expected_js, sv.inject_meta({:updateUrl => nil})
	end

	test 'inject meta add' do
		js = <<END
// ==UserScript==
// @name		A Test!
// @description		Unit test.
// @version 1.0
// @namespace http://greasyfork.local/users/1
// ==/UserScript==
foo.baz();
END
		sv = ScriptVersion.new
		sv.code = js
		rewritten_js = sv.inject_meta({:updateURL => 'http://example.com'})
		expected_js = "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n// @version 1.0\n// @namespace http://greasyfork.local/users/1\n// @updateURL http://example.com\n// ==/UserScript==\nfoo.baz();\n"
		assert_equal expected_js, rewritten_js
	end

	test 'inject meta add if missing is missing' do
		js = <<END
// ==UserScript==
// @name		A Test!
// @description		Unit test.
// @version 1.0
// @namespace http://greasyfork.local/users/1
// ==/UserScript==
foo.baz();
END
		sv = ScriptVersion.new
		sv.code = js
		rewritten_js = sv.inject_meta({}, {:updateURL => 'http://example.com'})
		expected_js = "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n// @version 1.0\n// @namespace http://greasyfork.local/users/1\n// @updateURL http://example.com\n// ==/UserScript==\nfoo.baz();\n"
		assert_equal expected_js, rewritten_js
	end

	test 'inject meta add if missing isnt missing' do
		js = <<END
// ==UserScript==
// @name		A Test!
// @description		Unit test.
// @updateURL http://example.com
// @version 1.0
// @namespace http://greasyfork.local/users/1
// ==/UserScript==
foo.baz();
END
		sv = ScriptVersion.new
		sv.code = js
		rewritten_js = sv.inject_meta({}, {:updateURL => 'http://example.net'})
		expected_js = "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n// @updateURL http://example.com\n// @version 1.0\n// @namespace http://greasyfork.local/users/1\n// ==/UserScript==\nfoo.baz();\n"
		assert_equal expected_js, rewritten_js
	end

	test 'calculate rewritten' do
		js = <<END
// ==UserScript==
// @name		A Test!
// @description		Unit test.
// @updateURL		http://example.com
// @namespace		http://greasyfork.local/users/1
// ==/UserScript==
foo.baz();
END
		sv = ScriptVersion.new
		sv.code = js
		sv.version = '123'
		sv.script = Script.find(1)
		sv.rewritten_code = sv.calculate_rewritten_code
		sv.save!
		expected_js = "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n// @namespace		http://greasyfork.local/users/1\n// @version 123\n// ==/UserScript==\nfoo.baz();\n"
		assert_equal expected_js, sv.rewritten_code
	end	

	test 'calculate rewritten no meta' do
		js = <<END
foo.baz();
END
		script = Script.new
		script.user = User.find(1)
		sv = ScriptVersion.new
		sv.script = script
		sv.code = js
		sv.version = '123'
		assert_nil sv.calculate_rewritten_code
	end

	test 'calculate rewritten meta not at top' do
		script = Script.find(12)
		expected_js = <<END
/* License info is here */
// ==UserScript==
// @name		A Test!
// @namespace		http://example.com/1
// @description		Unit test.
// @version		1
// ==/UserScript==
foo.baz();
END
		assert_equal expected_js, script.script_versions.first.calculate_rewritten_code
	end

	test 'validate require disallowed' do
		script = get_valid_script
		script_version = script.script_versions.first
		script_version.code = <<END
// ==UserScript==
// @name		A Test!
// @description		Unit test.
// @require		http://example.com
// @version 1.0
// @namespace http://greasyfork.local/users/1
// ==/UserScript==
var foo = "bar";
END
		assert !script_version.valid?
		assert_equal 1, script_version.errors.size
		assert script_version.errors.full_messages.first.include?('@require'), script_version.errors.full_messages.first
	end

	test 'validate require exemption' do
		script = get_valid_script
		script_version = script.script_versions.first
		script_version.code = <<END
// ==UserScript==
// @name		A Test!
// @description		Unit test.
// @version 1.0
// @namespace http://greasyfork.local/users/1
// @require		http://ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js
// ==/UserScript==
var foo = "bar";
END
		assert script_version.valid?, script_version.errors.full_messages.to_s
	end

	test 'validate require disallowed accept assessment' do
		script = get_valid_script
		script_version = script.script_versions.first
		script_version.code = <<END
// ==UserScript==
// @name		A Test!
// @description		Unit test.
// @require		http://example.com
// @version 1.0
// @namespace http://greasyfork.local/users/1
// ==/UserScript==
var foo = "bar";
END
		script_version.accepted_assessment = true
		script.apply_from_script_version(script_version)
		assert script_version.valid?
		assert_not_empty script.assessments
		assert script.assessments.first.details == 'http://example.com'
		assert_not_nil script.assessments.first.assessment_reason
		assert script.assessments.first.assessment_reason.name == '@require', script.assessments.first.assessment_reason.name
	end

	test 'validate disallowed code' do
		script = get_valid_script
		script_version = script.script_versions.first
		script_version.code = <<END
// ==UserScript==
// @name		A Test!
// @description		Unit test.
// @version 1.0
// @namespace http://greasyfork.local/users/1
// ==/UserScript==
function Like(p) {}
END
		assert !script_version.valid?
		assert_equal 1, script_version.errors.to_a.length
	end

	test 'update code with changing version' do
		script = Script.find(3)
		assert script.valid? and script.script_versions.length == 1 and script.script_versions.first.valid?
		sv = ScriptVersion.new
		sv.code = "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n// @version 1.2\n// @namespace http://greasyfork.local/users/1\n// ==/UserScript==\nvar foo = 2;"
		sv.script = script
		sv.calculate_all
		assert sv.valid?, sv.errors.full_messages.join(' ')
		assert_equal '1.2', sv.version
	end

	test 'update code without changing version' do
		script = Script.find(3)
		assert script.valid? and script.script_versions.length == 1 and script.script_versions.first.valid?
		sv = ScriptVersion.new
		sv.code = "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n// @version 1.1\n// @namespace http://greasyfork.local/users/1\n// ==/UserScript==\nvar foo = 2;"
		sv.script = script
		sv.calculate_all
		assert !sv.valid?
		assert_equal 1, sv.errors.to_a.length
	end

	test 'update code without changing version with override' do
		script = Script.find(3)
		assert script.valid? and script.script_versions.length == 1 and script.script_versions.first.valid?
		sv = ScriptVersion.new
		sv.code = "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n// @version 1.1\n// @namespace http://greasyfork.local/users/1\n// ==/UserScript==\nvar foo = 2;"
		sv.script = script
		sv.calculate_all
		sv.version_check_override = true
		assert sv.valid?, sv.errors.full_messages.join(' ')
		assert_equal '1.1', sv.version
	end

	test 'update code without changing version with be_lenient' do
		script = Script.find(3)
		assert script.valid? and script.script_versions.length == 1 and script.script_versions.first.valid?
		sv = ScriptVersion.new
		sv.code = "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n// @version 1.1\n// @namespace http://greasyfork.local/users/1\n// ==/UserScript==\nvar foo = 2;"
		sv.script = script
		sv.calculate_all
		sv.do_lenient_saving
		assert sv.valid?, sv.errors.full_messages.join(' ')
	end

	test 'missing version' do
		script = Script.new
		script.user = User.find(1)
		sv = ScriptVersion.new
		sv.script = script
		# valid with the version
		sv.code = "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n// @version 1.1\n// @namespace http://greasyfork.local/users/1\n// ==/UserScript==\nvar foo = 2;"
		sv.calculate_all
		assert sv.valid?, sv.errors.full_messages.join(' ')
		# invalid without
		sv.code = "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n// @namespace http://greasyfork.local/users/1\n// ==/UserScript==\nvar foo = 2;"
		sv.calculate_all
		assert !sv.valid?, sv.errors.full_messages.join(' ')
	end

	test 'add missing version' do
		script = Script.new
		script.user = User.find(1)
		sv = ScriptVersion.new
		sv.script = script
		# valid with the version
		sv.code = "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n// @version 1.1\n\n// @namespace http://greasyfork.local/users/1// ==/UserScript==\nvar foo = 2;"
		sv.calculate_all
		assert sv.valid?, sv.errors.full_messages.join(' ')
		# invalid without
		sv.code = "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n\n// @namespace http://greasyfork.local/users/1// ==/UserScript==\nvar foo = 2;"
		sv.add_missing_version = true
		sv.calculate_all
		assert sv.valid?
		assert /0\.0\.1\.20/ =~ sv.version
	end

	test 'update code without version previous had generated version' do
		script = Script.find(4)
		assert script.valid? and script.script_versions.length == 1 and script.script_versions.first.valid?
		old_version = script.script_versions.first.version
		sv = ScriptVersion.new
		sv.code = "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n// @namespace http://greasyfork.local/users/1\n// ==/UserScript==\nvar foo = 2;"
		sv.script = script
		sv.calculate_all
		assert sv.valid?, sv.errors.full_messages.join(' ')
		assert /^0\.0\.1\.[0-9]{14}$/ =~ sv.version
		assert sv.version != old_version
	end

	test 'update code without version previous had explicit version' do
		script = Script.find(5)
		assert script.valid? and script.script_versions.length == 1 and script.script_versions.first.valid?
		old_version = script.script_versions.first.version
		sv = ScriptVersion.new
		sv.code = "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n// @namespace http://greasyfork.local/users/1\n// ==/UserScript==\nvar foo = 2;"
		sv.script = script
		sv.calculate_all
		assert !sv.valid?
		assert_equal 1, sv.errors.to_a.length
	end

	test 'missing namespace' do
		script = Script.new
		script.user = User.find(1)
		sv = ScriptVersion.new
		sv.script = script
		# valid with the namespace
		sv.code = "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n// @version 1.1\n// @namespace http://greasyfork.local/users/1\n// ==/UserScript==\nvar foo = 2;"
		sv.calculate_all
		assert sv.valid?, sv.errors.full_messages.join(' ')
		# invalid without
		sv.code = "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n// @version 1.1\n// ==/UserScript==\nvar foo = 2;"
		sv.calculate_all
		assert !sv.valid?
	end

	test 'add missing namespace' do
		script = Script.new
		script.user = User.find(1)
		sv = ScriptVersion.new
		sv.script = script
		sv.code = "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n// @version 1.1\n// ==/UserScript==\nvar foo = 2;"
		sv.calculate_all
		assert !sv.valid?
		sv.add_missing_namespace = true
		sv.calculate_all
		assert_equal "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n// @version 1.1\n// @namespace http://greasyfork.local/users/1\n// ==/UserScript==\nvar foo = 2;", sv.rewritten_code
		assert sv.valid?, sv.errors.full_messages.inspect
	end

	test 'add missing namespace based on previous version' do
		script = Script.find(6)
		sv = ScriptVersion.new
		sv.script = script
		sv.code = "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n// @version 1.2\n// ==/UserScript==\nvar foo = 2;"
		sv.calculate_all
		assert sv.valid?, sv.errors.full_messages.inspect
		assert_equal "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n// @version 1.2\n// @namespace http://example.com\n// ==/UserScript==\nvar foo = 2;", sv.rewritten_code
	end

	test 'retain namespace' do
		script = Script.find(6)
		sv = ScriptVersion.new
		sv.script = script
		sv.code = "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n// @version 1.2\n// @namespace http://example.com\n// ==/UserScript==\nvar foo = 2;"
		sv.calculate_all
		assert_equal "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n// @version 1.2\n// @namespace http://example.com\n// ==/UserScript==\nvar foo = 2;", sv.rewritten_code
		assert sv.valid?, sv.errors.full_messages.inspect
	end

	test 'change namespace' do
		script = Script.find(6)
		sv = ScriptVersion.new
		sv.script = script
		sv.code = "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n// @version 1.2\n// @namespace http://example.com/1\n// ==/UserScript==\nvar foo = 2;"
		sv.calculate_all
		assert !sv.valid?
	end

	test 'change namespace with override' do
		script = Script.find(6)
		sv = ScriptVersion.new
		sv.script = script
		sv.code = "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n// @version 1.2\n// @namespace http://example.com/1\n// ==/UserScript==\nvar foo = 2;"
		sv.namespace_check_override = true
		sv.calculate_all
		assert_equal "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n// @version 1.2\n// @namespace http://example.com/1\n// ==/UserScript==\nvar foo = 2;", sv.rewritten_code
		assert sv.valid?
	end

	test 'missing description' do
		js = <<END
// ==UserScript==
// @name		A Test!
// @namespace		http://example.com/1
// @version		1
// ==/UserScript==
foo.baz();
END
		sv = ScriptVersion.new
		sv.code = js
		script = Script.new
		sv.script = script
		sv.calculate_all(script.description)
		script.apply_from_script_version(sv)
		assert script.description.nil?
		assert !script.valid?
	end	

	test 'missing description previous had description' do
		js = <<END
// ==UserScript==
// @name		A Test!
// @namespace		http://example.com/1
// @version		1
// ==/UserScript==
foo.baz();
END
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
		js = <<END
// ==UserScript==
// @description		A Test!
// @namespace		http://example.com/1
// @version		1
// ==/UserScript==
foo.baz();
END
		sv = ScriptVersion.new
		sv.code = js
		script = Script.find(13)
		sv.script = script
		sv.calculate_all(script.description)
		script.apply_from_script_version(sv)
		assert_nil script.name
		assert !script.valid?
	end	

	test 'library missing name previous had name' do
		js = <<END
// ==UserScript==
// @description		A Test!
// @namespace		http://example.com/1
// @version		1
// ==/UserScript==
foo.baz();
END
		sv = ScriptVersion.new
		sv.code = js
		script = Script.find(13)
		script.script_type_id = 3
		sv.script = script
		sv.calculate_all(script.description)
		script.apply_from_script_version(sv)
		assert_equal 'MyString', script.name
		assert script.valid?, script.errors.full_messages
	end	

	test 'linebreak only update code without changing version' do
		script = Script.find(3)
		assert script.valid? and script.script_versions.length == 1 and script.script_versions.first.valid?
		sv = ScriptVersion.new
		sv.code = script.script_versions.first.code.gsub("\n", "\r\n")
		sv.script = script
		sv.calculate_all
		assert sv.valid?
	end

	test 'get blanked code' do
		js = <<END
// ==UserScript==
// @name		A Test!
// @description		Unit test.
// @version 2
// @namespace whatever
// ==/UserScript==
var foo = "bar";
END
		sv = ScriptVersion.new
		sv.code = js
		sv.script = Script.new
		sv.calculate_all
		expected_meta = <<END
// ==UserScript==
// @name		A Test!
// @description		This script was deleted from Greasy Fork, and due to its negative effects, it has been automatically removed from your browser.
// @version 2.0.0.1
// @namespace whatever
// ==/UserScript==
END
		assert_equal expected_meta, sv.get_blanked_code
	end


	test 'get next version' do
		assert_equal '1.0.0.1', ScriptVersion.get_next_version('1')
		assert_equal '1.0.0.2', ScriptVersion.get_next_version('1.0.0.1')
		assert_equal '1.1.1.2', ScriptVersion.get_next_version('1.1.1.1')
		assert_equal '1.1.1.1b2a', ScriptVersion.get_next_version('1.1.1.1b1a')
	end

	test 'minified' do
		js = <<END
// ==UserScript==
// @name Test
// @description		A Test!
// @namespace		http://example.com/1
// @version		1
// ==/UserScript==
END
		sv = ScriptVersion.new
		sv.code = js
		script = Script.new
		script.user = User.first
		sv.script = script
		sv.calculate_all(script.description)
		script.apply_from_script_version(sv)
		# regular new script...
		assert sv.valid?, sv.errors.full_messages
		# now minified
		sv.code += "function a(){}" * 5000
		assert !sv.valid?
		# override
		sv.minified_confirmation = true
		assert sv.valid?
		# now an update
		sv.minified_confirmation = false
		script.save
		assert sv.valid?, sv.errors.full_messages
	end

	test 'use same script code between code and rewritten' do
		js = <<END
// ==UserScript==
// @name Test
// @description		A Test!
// @namespace		http://example.com/1
// @version		1
// ==/UserScript==
END
		sv = ScriptVersion.new
		sv.code = js
		script = Script.new
		script.user = User.first
		sv.script = script
		sv.calculate_all(script.description)
		script.apply_from_script_version(sv)
		assert sv.valid?, sv.errors.full_messages
		script.save
		sv.save
		# code and rewritten code should be the same object
		assert_not_nil sv.script_code_id
		assert_not_nil sv.rewritten_script_code_id
		assert_equal sv.code, sv.rewritten_code
		assert_equal sv.script_code_id, sv.rewritten_script_code_id
		# change the code, rewritten should stay the same
		sv.code += "\nvar foo = 'bar';"
		assert_not_equal sv.code, sv.rewritten_code
		# ...until we recalculate rewritten, then it should be the same as code again
		sv.calculate_all(script.description)
		script.save
		sv.save
		assert_equal sv.code, sv.rewritten_code
		assert_equal sv.script_code_id, sv.rewritten_script_code_id
		# now test a case where code and rewritten should stay different
		js = <<END
// ==UserScript==
// @name Test
// @description		A Test!
// @namespace		http://example.com/1
// @version		1
// @downloadURL http://example.com
// ==/UserScript==
END
		sv.code = js
		assert_not_equal sv.code, sv.rewritten_code
		sv.calculate_all(script.description)
		script.save
		sv.save
		assert_not_equal sv.code, sv.rewritten_code
		assert_not_equal sv.script_code_id, sv.rewritten_script_code_id
	end

	test 'reuse script code when not changed' do
		js = <<END
// ==UserScript==
// @name Test
// @description		A Test!
// @namespace		http://example.com/1
// @version		1
// ==/UserScript==
END
		sv = ScriptVersion.new
		sv.do_lenient_saving
		sv.code = js
		script = Script.new
		script.user = User.first
		sv.script = script
		sv.calculate_all(script.description)
		script.apply_from_script_version(sv)
		assert sv.valid?, sv.errors.full_messages
		script.save!
		sv.save!
		previous_script_code_id = sv.script_code_id
		previous_rewritten_script_code_id = sv.rewritten_script_code_id
		script.reload
		assert_not_nil script.get_newest_saved_script_version
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
		js = <<END
// ==UserScript==
// @name Test
// @description		A Test!
// @namespace		http://example.com/1
// @version		1
// @downloadURL http://example.com
// ==/UserScript==
END
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
		js = <<END
// ==UserScript==
// @name Test
// @description		A Test!
// @namespace		http://example.com/1
// @version		1
// @downloadURL http://example.com
// ==/UserScript==
var foo = "bar";
END
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
		js = <<END
// ==UserScript==
// @name Test
// @description		A Test!
// @namespace		http://example.com/1
// @version		1
// ==/UserScript==
var foo = "bar";
END
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

	test 'truncate description' do
		js = <<END
// ==UserScript==
// @name		A Test!
// @description		123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
// @version 1.0
// @namespace http://greasyfork.local/users/1
// ==/UserScript==
foo.baz();
END
		sv = ScriptVersion.new
		script = Script.new
		script.user = User.first
		sv.script = script
		sv.code = js
		sv.calculate_all
		script.apply_from_script_version(sv)
		assert script.description.length > 500
		assert !script.valid?
		assert script.errors.to_a.length == 1, script.errors.full_messages
		assert script.errors.full_messages.first.include?('Description'), script.errors.full_messages
		sv.do_lenient_saving
		sv.calculate_all
		script.apply_from_script_version(sv)
		assert script.valid?, script.errors.full_messages
		assert script.description.length == 500
	end
end
