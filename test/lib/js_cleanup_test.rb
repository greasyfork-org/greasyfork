require 'test_helper'
require 'js_cleanup'

class JsCleanupTest < ActiveSupport::TestCase
  test 'comments are stripped' do
    assert_equal(
      JsCleanup.cleanup('/* comment */ var foo = 1;'),
      JsCleanup.cleanup('/* tnemmoc */ var foo = 1;')
    )
  end

  test 'inline whitespace differences are ignored' do
    assert_equal(
      JsCleanup.cleanup('var foo = 1;'),
      JsCleanup.cleanup('var foo=1;')
    )
  end

  test 'line break differences are ignored' do
    assert_equal(
      JsCleanup.cleanup("var foo = 1;\nvar bar = 2;"),
      JsCleanup.cleanup("var foo = 1;\n\nvar bar = 2;")
    )
  end

  test 'indentation differences are ignored' do
    assert_equal(
      JsCleanup.cleanup("function foo() {\n\tvbar = 1;\n}"),
      JsCleanup.cleanup("function foo() {\nvbar = 1;\n}")
    )
  end

  test 'different variable names are ignored' do
    skip
    assert_equal(
      JsCleanup.cleanup("var foo = 1;\nvar bar = 2;"),
      JsCleanup.cleanup("var oof = 1;\nvar rab = 2;")
    )
  end

  test 'an invalid script' do
    assert_raises(JsCleanup::UncleanableException) do
      JsCleanup.cleanup('function foo() { var bar = 1; delete bar; }')
    end
  end

  test 'an invalid script - return' do
    assert_raises(JsCleanup::UncleanableException) do
      JsCleanup.cleanup('if (true) return')
    end
  end
end
