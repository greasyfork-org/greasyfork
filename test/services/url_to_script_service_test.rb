require 'test_helper'
class UrlToScriptServiceTest < ActiveSupport::TestCase
  test 'normal gf url' do
    assert_equal 1, UrlToScriptService.to_script('https://greasyfork.org/scripts/1', verify_existence: false)
  end

  test 'gf update url' do
    assert_equal 1, UrlToScriptService.to_script('https://update.greasyfork.org/scripts/1', verify_existence: false)
  end

  test 'non gf url' do
    assert_equal :non_gf_url, UrlToScriptService.to_script('https://example.org/scripts/1', verify_existence: false)
  end
end
