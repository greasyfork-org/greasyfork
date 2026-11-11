require 'test_helper'

class ScriptsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'code search rejects multiline queries' do
    sign_in users(:one)
    ScriptCodeSearch.expects(:search).never

    ["first\nsecond", "first\rsecond", "first\r\nsecond", "\n"].each do |query|
      get code_search_scripts_url(locale: :en), params: { c: query }
      assert_response :unprocessable_content
      assert_equal 'Code search query must be a single line', response.body
    end
  end

  test 'code search accepts a single-line dash-prefixed query' do
    sign_in users(:one)
    ScriptCodeSearch.expects(:search).with('--example', limit_to_ids: nil).returns([])

    get code_search_scripts_url(locale: :en, format: :json, host: 'api.greasyfork.local'), params: { c: '--example', meta: '1' }
    assert_response :ok
    assert_equal({ 'count' => 0 }, response.parsed_body)
  end

  test 'code search redirects blank queries' do
    sign_in users(:one)
    ScriptCodeSearch.expects(:search).never

    [nil, '', ' '].each do |query|
      get code_search_scripts_url(locale: :en), params: { c: query }
      assert_response :moved_permanently
    end
  end

  test 'render scripts as json' do
    stub_es(Script)
    get scripts_url(locale: :en, format: :json, host: 'api.greasyfork.local')
    assert_response :ok
  end

  test 'render script as json' do
    get script_url(Script.first, locale: :en, format: :json, host: 'api.greasyfork.local')
    assert_response :ok
  end

  test 'render script stats as json' do
    get stats_script_url(Script.first, locale: :en, format: :json, host: 'api.greasyfork.local')
    assert_response :ok
  end

  test 'render script stats as csv' do
    get stats_script_url(Script.first, locale: :en, format: :csv, host: 'api.greasyfork.local')
    assert_response :ok
  end

  test 'render library stats as json' do
    get stats_script_url(scripts(:library), locale: :en, format: :json, host: 'api.greasyfork.local')
    assert_response :ok
  end

  test 'render library stats as csv' do
    get stats_script_url(scripts(:library), locale: :en, format: :csv, host: 'api.greasyfork.local')
    assert_response :ok
  end

  test '410 for code on script deleted' do
    script = Script.first
    script.destroy!

    get user_js_script_url(script, name: script.url_name, locale: :en)
    assert_response :gone
  end

  test '404 for code on script does not exist yet' do
    id = Script.last.id + 1000
    get user_js_script_url(id, name: 'whatever', locale: :en)
    assert_response :not_found
  end
end
