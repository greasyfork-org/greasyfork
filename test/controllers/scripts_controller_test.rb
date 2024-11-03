require 'test_helper'

class ScriptsControllerTest < ActionDispatch::IntegrationTest
  test 'render scripts as json' do
    stub_es(Script)
    get scripts_url(locale: :en, format: :json)
    assert_response :ok
  end

  test 'render script as json' do
    get script_url(Script.first, locale: :en, format: :json)
    assert_response :ok
  end

  test 'generates a placeholder for nginx on record not found' do
    script = Script.first
    script.destroy!
    FileUtils.rm_r(Rails.application.config.cached_code_404_path) if Dir.exist?(Rails.application.config.cached_code_404_path)
    assert_not File.exist?(Rails.application.config.cached_code_404_path.join('greasyfork', 'latest', 'scripts', script.id.to_s))

    get user_js_script_url(script, name: script.url_name, locale: :en)
    assert_response :not_found

    assert_path_exists(Rails.application.config.cached_code_404_path.join('greasyfork', 'latest', 'scripts', script.id.to_s))
  end

  test 'does not generate a placeholder for nginx on record not found for future IDs' do
    FileUtils.rm_r(Rails.application.config.cached_code_404_path) if Dir.exist?(Rails.application.config.cached_code_404_path)

    id = Script.last.id + 1000
    get user_js_script_url(id, name: 'whatever', locale: :en)
    assert_response :not_found

    refute_path_exists(Rails.application.config.cached_code_404_path.join('greasyfork', 'latest', 'scripts', id.to_s))
  end
end
