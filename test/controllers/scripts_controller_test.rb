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

  test 'code search rejects fewer than three characters for both backends' do
    sign_in users(:mod)
    ScriptCodeSearch.expects(:search).never
    ElasticsearchCodeSearch.expects(:search).never

    backends = [nil, '1']
    %w[a ab é字].each do |query|
      backends.each do |backend|
        get code_search_scripts_url(locale: :en), params: { c: query, elasticsearch: backend }
        assert_response :unprocessable_content
        assert_equal 'Code search requires at least 3 characters.', response.body
      end
    end
  end

  test 'code search accepts three characters' do
    sign_in users(:one)
    ScriptCodeSearch.expects(:search).with('é字a', limit_to_ids: nil).returns([])
    get code_search_scripts_url(locale: :en, format: :json, host: 'api.greasyfork.local'), params: { c: 'é字a' }
    assert_response :ok
  end

  test 'code search reports elasticsearch timeouts in html' do
    sign_in users(:mod)
    error = ElasticsearchCodeSearch::SearchTimeoutError.new('timed out')
    ElasticsearchCodeSearch.stubs(:search).raises(error)
    Sentry.expects(:capture_exception).with(error)

    get code_search_scripts_url(locale: :en), params: { c: 'test', elasticsearch: '1' }
    assert_response :gateway_timeout
    assert_equal 'Code search timed out. Please try a more specific search or try again later.', response.body
  end

  test 'code search reports elasticsearch timeouts in api responses' do
    sign_in users(:mod)
    error = ElasticsearchCodeSearch::SearchTimeoutError.new('timed out')
    ElasticsearchCodeSearch.stubs(:search).raises(error)
    Sentry.expects(:capture_exception).with(error).twice

    get code_search_scripts_url(locale: :en, format: :json, host: 'api.greasyfork.local'), params: { c: 'test', elasticsearch: '1' }
    assert_response :gateway_timeout
    assert_equal({ 'error' => 'Code search timed out. Please try a more specific search or try again later.' }, response.parsed_body)

    get code_search_scripts_url(locale: :en, format: :jsonp, host: 'api.greasyfork.local'), params: { c: 'test', elasticsearch: '1', callback: 'callback' }
    assert_response :gateway_timeout
    assert_includes response.body, 'callback('
    assert_includes response.body, 'Code search timed out.'
  end

  test 'only moderators can enable elasticsearch code search' do
    sign_in users(:one)
    ScriptCodeSearch.expects(:search).with('test', limit_to_ids: nil).returns([])
    ElasticsearchCodeSearch.expects(:search).never
    get code_search_scripts_url(locale: :en, format: :json, host: 'api.greasyfork.local'), params: { c: 'test', elasticsearch: '1' }
    assert_response :ok
  end

  test 'moderators can enable elasticsearch code search' do
    sign_in users(:mod)
    ScriptCodeSearch.expects(:search).never
    ElasticsearchCodeSearch.expects(:search).with('test', limit_to_ids: nil).returns([])
    get code_search_scripts_url(locale: :en, format: :json, host: 'api.greasyfork.local'), params: { c: 'test', elasticsearch: '1' }
    assert_response :ok
  end

  test 'code search options retain experimental and deleted filters' do
    sign_in users(:mod)
    ElasticsearchCodeSearch.expects(:search).with('test', limit_to_ids: nil).returns([])
    get code_search_scripts_url(locale: :en), params: { c: 'test', elasticsearch: '1', include_deleted: '1' }
    assert_response :ok
    assert_select '#script-list-sort a[href*="elasticsearch=1"][href*="include_deleted=1"]'
    assert_select '#script-language-filter a[href*="elasticsearch=1"][href*="include_deleted=1"]'
  end

  test 'only moderators see the experimental code search option' do
    sign_in users(:one)
    get search_url(locale: :en)
    assert_response :ok
    assert_select '#code-search-elasticsearch', count: 0
    assert_select '#code-search input[name=c][minlength="3"]', count: 1

    sign_out users(:one)
    sign_in users(:mod)
    get search_url(locale: :en)
    assert_response :ok
    assert_select '#code-search-elasticsearch[name=elasticsearch][value="1"]', count: 1
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
