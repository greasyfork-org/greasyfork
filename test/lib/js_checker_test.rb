require 'test_helper'
require 'js_checker'

class JsCheckerTest < ActiveSupport::TestCase
  test 'valid JS is valid' do
    jsc = ::JsChecker.new('var foo = 1;')
    assert jsc.check, jsc.errors
    assert_empty jsc.errors
  end

  test 'valid syntax with error' do
    jsc = ::JsChecker.new('foo.bar')
    assert jsc.check, jsc.errors
    assert_empty jsc.errors
  end

  test 'ES6 syntax' do
    jsc = ::JsChecker.new('let foo = "bar";')
    assert jsc.check, jsc.errors
    assert_empty jsc.errors
  end

  test 'invalid JS is in valid' do
    jsc = ::JsChecker.new('foo bar')
    assert_not jsc.check
    assert_not_empty jsc.errors
  end

  test 'logical nullish' do
    jsc = ::JsChecker.new('let x = null; x ??= 1;')
    assert jsc.check
    assert_empty jsc.errors
  end
end
