require 'test_helper'
require 'js_executor'

class JsExecutorTest < ActiveSupport::TestCase
  test 'extract URLS' do
    assert_equal ['http://example.com'], JsExecutor.extract_urls("window.location.assign('http://example.com')").to_a
  end

  test 'extract via set' do
    assert_equal ['http://example.com'], JsExecutor.extract_urls("window.location = 'http://example.com'").to_a
  end

  test 'ignoring non-strings where URLs should be' do
    assert_empty JsExecutor.extract_urls('window.location.assign(function() {})').to_a
  end

  test 'extract urls does not die on circular references on function call' do
    assert_empty JsExecutor.extract_urls(<<~JS).to_a
      a = {}
      a.foo = a
      window.location.assign(a)
    JS
  end

  test 'extract urls does not die on circular references on set' do
    assert_empty JsExecutor.extract_urls(<<~JS).to_a
      a = {}
      a.foo = a
      window.location = a
    JS
  end
end
