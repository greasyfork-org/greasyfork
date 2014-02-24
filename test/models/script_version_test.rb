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
// ==/UserScript==
foo.baz();
END
		sv = ScriptVersion.new
		sv.code = js
		rewritten_js = sv.inject_meta({:name => 'Something else'})
		expected_js = "// ==UserScript==\n// @name		Something else\n// @description		Unit test.\n// ==/UserScript=="
		assert_equal expected_js, rewritten_js
	end

	test 'inject meta remove' do
		js = <<END
// ==UserScript==
// @name		A Test!
// @description		Unit test.
// ==/UserScript==
foo.baz();
END
		sv = ScriptVersion.new
		sv.code = js
		rewritten_js = sv.inject_meta({:name => nil})
		expected_js = "// ==UserScript==\n// @description		Unit test.\n// ==/UserScript=="
		assert_equal expected_js, rewritten_js
	end

	test 'inject meta remove not present' do
		js = <<END
// ==UserScript==
// @name		A Test!
// @description		Unit test.
// ==/UserScript==
foo.baz();
END
		sv = ScriptVersion.new
		sv.code = js
		expected_js = "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n// ==/UserScript=="
		assert_equal expected_js, sv.inject_meta({:updateUrl => nil})
	end

	test 'inject meta add' do
		js = <<END
// ==UserScript==
// @name		A Test!
// @description		Unit test.
// ==/UserScript==
foo.baz();
END
		sv = ScriptVersion.new
		sv.code = js
		rewritten_js = sv.inject_meta({:updateURL => 'http://example.com'})
		expected_js = "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n// @updateURL http://example.com\n// ==/UserScript=="
		assert_equal expected_js, rewritten_js
	end

	test 'calculate rewritten' do
		js = <<END
// ==UserScript==
// @name		A Test!
// @description		Unit test.
// ==/UserScript==
foo.baz();
END
		sv = ScriptVersion.new
		sv.code = js
		sv.version = '123'
		sv.script = Script.find(1)
		sv.rewritten_code = sv.calculate_rewritten_code
		sv.save!
		expected_js = "// ==UserScript==\n// @name		A Test!\n// @description		Unit test.\n// @version 123\n// @updateURL https://greasyfork.local/scripts/1/code.meta.js\n// @downloadURL https://greasyfork.local/scripts/1/code.user.js\n// @namespace https://greasyfork.local/scripts/1\n// ==/UserScript==\nfoo.baz();\n"
		assert_equal expected_js, sv.rewritten_code
	end	

	test 'calculate rewritten no meta' do
		js = <<END
foo.baz();
END
		sv = ScriptVersion.new
		sv.code = js
		sv.version = '123'
		assert_equal 'placeholder', sv.calculate_rewritten_code
	end

	test 'validate require disallowed' do
		script = get_valid_script
		script_version = script.script_versions.first
		script_version.code = <<END
// ==UserScript==
// @name		A Test!
// @description		Unit test.
// @require		http://example.com
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
// @require		http://ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js
// ==/UserScript==
var foo = "bar";
END
		assert script_version.valid?, script_version.errors.full_messages.to_s
	end

	test 'validate disallowed code' do
		script = get_valid_script
		script_version = script.script_versions.first
		script_version.code = <<END
// ==UserScript==
// @name		A Test!
// @description		Unit test.
// ==/UserScript==
function Like(p) {}
END
		assert !script_version.valid?
	end

end
