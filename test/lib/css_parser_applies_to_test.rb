require 'test_helper'

class CssParserAppliesToTest < ActiveSupport::TestCase
  def get_applies_tos(code)
    CssParser.calculate_applies_to_names(code)
  end

  test 'applies to everything' do
    css = <<~CSS
      a { color: red; }
    CSS
    assert_equal [], get_applies_tos(css)
  end

  test 'applies to single domain' do
    css = <<~CSS
      @-moz-document domain(example.com) {
        a { color: red; }
      }
    CSS
    assert_equal [{text: 'example.com', domain: true, tld_extra: false}], get_applies_tos(css)
  end

  test 'applies to single url' do
    css = <<~CSS
      @-moz-document url('http://www.example.com') {
        a { color: red; }
      }
    CSS
    assert_equal [{text: 'example.com', domain: true, tld_extra: false}], get_applies_tos(css)
  end

  test 'applies to single url-prefix' do
    css = <<~CSS
      @-moz-document url-prefix("http://www.example.com/") {
        a { color: red; }
      }
    CSS
    assert_equal [{text: 'example.com', domain: true, tld_extra: false}], get_applies_tos(css)
  end

  test 'applies to single url-prefix with domain wildcard' do
    css = <<~CSS
      @-moz-document url-prefix("http://example") {
        a { color: red; }
      }
    CSS
    assert_equal [{text: 'http://example*', domain: false, tld_extra: false}], get_applies_tos(css)
  end

  test 'applies to single regexp' do
    css = <<~CSS
      @-moz-document regexp(".*example.*") {
        a { color: red; }
      }
    CSS
    assert_equal [{text: '.*example.*', domain: false, tld_extra: false}], get_applies_tos(css)
  end

  test 'multiple values in a rule' do
    css = <<~CSS
      @-moz-document domain(example.com), domain(example2.com) {
        a { color: red; }
      }
    CSS
    assert_equal [{text: 'example.com', domain: true, tld_extra: false}, {text: 'example2.com', domain: true, tld_extra: false}], get_applies_tos(css)
  end

  test 'multiple document blocks' do
    css = <<~CSS
      @-moz-document domain(example.com) {
        a { color: red; }
      }
      @-moz-document domain(example2.com) {
        a { color: red; }
      }
    CSS
    assert_equal [{text: 'example.com', domain: true, tld_extra: false}, {text: 'example2.com', domain: true, tld_extra: false}], get_applies_tos(css)
  end
end