require 'js_executor'

class JsExecutorTest < ActiveSupport::TestCase
  test 'extract URLS' do
    assert_equal ['http://example.com'], JsExecutor.extract_urls("window.location.assign('http://example.com')").to_a
  end

  test 'ignoring non-strings where URLs should be' do
    assert_empty JsExecutor.extract_urls('window.location.assign(function() {})').to_a
  end
end
