require 'test_helper'

class ScriptsControllerTest < ActionDispatch::IntegrationTest
  test 'render scripts as json' do
    stub_es(Script)
    get scripts_url(locale: :en, format: :json, host: 'api.greasyfork.local')
    assert_response :ok
  end

  test 'render script as json' do
    get script_url(Script.first, locale: :en, format: :json, host: 'api.greasyfork.local')
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
