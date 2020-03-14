require 'test_helper'
require 'script_importer/base_script_importer'

class BaseScriptImporterTest < ActiveSupport::TestCase
  test 'absolutized references' do
    new_html = ScriptImporter::BaseScriptImporter.absolutize_references('<b><img src="/relative.png"></b>', 'http://www.example.com')
    assert_equal '<b><img src="http://www.example.com/relative.png"></b>', new_html
  end

  test 'absolutized references no change' do
    new_html = ScriptImporter::BaseScriptImporter.absolutize_references('<b><img src="http://www.example2.com/relative.png"></b>', 'http://www.example.com')
    assert_nil new_html
  end

  test 'absolutized references one changed one not' do
    new_html = ScriptImporter::BaseScriptImporter.absolutize_references('<b><img src="/relative.png"><img src="http://www.example2.com/relative.png"></b>', 'http://www.example.com')
    assert_equal '<b><img src="http://www.example.com/relative.png"><img src="http://www.example2.com/relative.png"></b>', new_html
  end
end
