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
		assert_equal "\nvar foo = 'bar';\nfoo.baz();\n", ScriptVersion.get_code_block(js)
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
		assert_equal "var foo = 'bar';\n\nfoo.baz();\n", ScriptVersion.get_code_block(js)
	end

	test 'get code block with no meta' do
		js = <<END
var foo = 'bar';
foo.baz();
END
		assert_equal "var foo = 'bar';\nfoo.baz();\n", ScriptVersion.get_code_block(js)
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
// @namespace		http://example.com/1
// ==/UserScript==
foo.baz();
END
		sv = ScriptVersion.new
		sv.code = js
		sv.version = '123'
		sv.script = Script.find(1)
		sv.rewritten_code = sv.calculate_rewritten_code
		sv.save!
		expected_js = "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n// @namespace		http://example.com/1\n// @version 123\n// ==/UserScript==\nfoo.baz();\n"
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

end
