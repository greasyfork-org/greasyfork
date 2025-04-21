require 'test_helper'

class ScriptSubresourceTest < ActiveSupport::TestCase
  def get_script_with_code(code)
    script = valid_script
    sv = script.script_versions.first
    script.script_versions.first.code = code
    sv.calculate_all
    script.apply_from_script_version(sv)
    script
  end

  test 'saving subresources and then not changing' do
    script = get_script_with_code(<<~JS)
      // ==UserScript==
      // @name		Subresource test
      // @description		description
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // @require https://ajax.googleapis.com/test.js
      // ==/UserScript==
      foo.baz();
    JS
    assert_difference -> { Subresource.count } => 1 do
      script.save!
    end
    assert_equal(1, script.subresource_usages.count)
    assert_equal(1, script.subresources.count)
    assert_equal 'https://ajax.googleapis.com/test.js', script.subresources.first.url

    sv = script.script_versions.new(code: <<~JS)
      // ==UserScript==
      // @name		Subresource test
      // @description		description
      // @version 1.1
      // @namespace http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // @require https://ajax.googleapis.com/test.js
      // ==/UserScript==
      foo.bar.baz();
    JS
    sv.calculate_all
    script.apply_from_script_version(sv)
    assert_no_difference -> { Subresource.count } do
      script.save!
    end
    assert_equal(1, script.subresource_usages.count)
    assert_equal(1, script.subresources.count)
    assert_equal 'https://ajax.googleapis.com/test.js', script.subresources.first.url
  end

  test 'saving subresource and then dropping it' do
    script = get_script_with_code(<<~JS)
      // ==UserScript==
      // @name		Subresource test
      // @description		description
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // @require https://ajax.googleapis.com/test.js
      // ==/UserScript==
      foo.baz();
    JS
    assert_difference -> { Subresource.count } => 1 do
      script.save!
    end
    assert_equal(1, script.subresource_usages.count)
    assert_equal(1, script.subresources.count)
    assert_equal 'https://ajax.googleapis.com/test.js', script.subresources.first.url

    sv = script.script_versions.new(code: <<~JS)
      // ==UserScript==
      // @name		Subresource test
      // @description		description
      // @version 1.1
      // @namespace http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // ==/UserScript==
      foo.bar.baz();
    JS
    sv.calculate_all
    script.apply_from_script_version(sv)
    assert_no_difference -> { Subresource.count } do
      script.save!
    end
    assert_empty script.subresource_usages
    assert_empty script.subresources
  end

  test 'saving with subresource integrity, equal format' do
    script = get_script_with_code(<<~JS)
      // ==UserScript==
      // @name		Subresource test
      // @description		description
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // @require https://ajax.googleapis.com/test.js#md5=123
      // ==/UserScript==
      foo.baz();
    JS
    assert_difference -> { Subresource.count } => 1 do
      script.save!
    end
    assert_equal(1, script.subresource_usages.count)
    assert_equal(1, script.subresources.count)
    assert_equal 'https://ajax.googleapis.com/test.js', script.subresources.first.url
    assert_equal 'md5', script.subresource_usages.first.algorithm
    assert_equal '123', script.subresource_usages.first.integrity_hash
  end

  test 'saving with subresource integrity, hyphen format' do
    script = get_script_with_code(<<~JS)
      // ==UserScript==
      // @name		Subresource test
      // @description		description
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // @require https://ajax.googleapis.com/test.js#md5-123
      // ==/UserScript==
      foo.baz();
    JS
    assert_difference -> { Subresource.count } => 1 do
      script.save!
    end
    assert_equal(1, script.subresource_usages.count)
    assert_equal(1, script.subresources.count)
    assert_equal 'https://ajax.googleapis.com/test.js', script.subresources.first.url
    assert_equal 'md5', script.subresource_usages.first.algorithm
    assert_equal '123', script.subresource_usages.first.integrity_hash
  end

  test 'saving with subresource integrity for normally disallowed domain, hyphen format' do
    script = get_script_with_code(<<~JS)
      // ==UserScript==
      // @name		Subresource test
      // @description		description
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // @require https://example.com/test.js#md5-123
      // ==/UserScript==
      foo.baz();
    JS
    assert_difference -> { Subresource.count } => 1 do
      script.save!
    end
    assert_equal(1, script.subresource_usages.count)
    assert_equal(1, script.subresources.count)
    assert_equal 'https://example.com/test.js', script.subresources.first.url
    assert_equal 'md5', script.subresource_usages.first.algorithm
    assert_equal '123', script.subresource_usages.first.integrity_hash
  end

  test 'saving subresources that was previously used by another' do
    script = get_script_with_code(<<~JS)
      // ==UserScript==
      // @name		Subresource test
      // @description		description
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // @require https://ajax.googleapis.com/test.js
      // ==/UserScript==
      foo.baz();
    JS
    assert_difference -> { Subresource.count } => 1 do
      script.save!
    end
    assert_equal(1, script.subresource_usages.count)
    assert_equal(1, script.subresources.count)
    assert_equal 'https://ajax.googleapis.com/test.js', script.subresources.first.url

    script = get_script_with_code(<<~JS)
      // ==UserScript==
      // @name		Subresource test
      // @description		description
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // @require https://ajax.googleapis.com/test.js
      // ==/UserScript==
      foo.bar.baz();
    JS
    assert_no_difference -> { Subresource.count } do
      script.save!
    end
    assert_equal(1, script.subresource_usages.count)
    assert_equal(1, script.subresources.count)
    assert_equal 'https://ajax.googleapis.com/test.js', script.subresources.first.url

    assert_equal 2, Subresource.last.scripts.count
  end

  test '@resource subresources' do
    script = get_script_with_code(<<~JS)
      // ==UserScript==
      // @name		Subresource test
      // @description		description
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // @resource testScript https://ajax.googleapis.com/test.js
      // ==/UserScript==
      foo.baz();
    JS
    assert_difference -> { Subresource.count } => 1 do
      script.save!
    end
    assert_equal(1, script.subresource_usages.count)
    assert_equal(1, script.subresources.count)
    assert_equal 'https://ajax.googleapis.com/test.js', script.subresources.first.url
  end

  test 'data: subresources are ignored' do
    script = get_script_with_code(<<~JS)
      // ==UserScript==
      // @name		Subresource test
      // @description		description
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // @require data:application/javascript,var foo={}
      // ==/UserScript==
      foo.baz();
    JS
    assert_no_difference -> { Subresource.count } do
      script.save!
    end
  end

  test 'base64 subresources' do
    script = get_script_with_code(<<~JS)
      // ==UserScript==
      // @name		Subresource test
      // @description		description
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include *
      // @license MIT
      // @require https://ajax.googleapis.com/test.js#sha256=FgpCb/KJQlLNfOu91ta32o/NMZxltwRo8QtmkMRdAu8=
      // ==/UserScript==
      foo.baz();
    JS
    assert_difference -> { Subresource.count } => 1 do
      script.save!
    end
    assert_equal(1, script.subresource_usages.count)
    assert_equal(1, script.subresources.count)
    assert_equal 'https://ajax.googleapis.com/test.js', script.subresources.first.url
    assert_equal 'sha256', script.subresource_usages.first.algorithm
    assert_equal 'base64', script.subresource_usages.first.encoding
    assert_equal 'FgpCb/KJQlLNfOu91ta32o/NMZxltwRo8QtmkMRdAu8=', script.subresource_usages.first.integrity_hash
  end
end
