require 'test_helper'

class LocalizedRequestTest < ActionController::TestCase
  # Dummy to pretend we're a controller
  def self.before_action(*args); end

  def self.helper_method(*args); end

  include LocalizedRequest

  test 'parse accept-language' do
    assert_equal %w[da en-GB en], parse_accept_language('da, en-gb;q=0.8, en;q=0.7')
  end

  test 'parse accept-language no header' do
    assert_empty parse_accept_language(nil)
  end

  test 'detect locale' do
    top, preferred = detect_locale(nil, 'zu, fr-FR;q=0.8, fr;q=0.7')
    assert_equal 'fr', top.code
    assert_equal 'zu', preferred.code
  end
end
