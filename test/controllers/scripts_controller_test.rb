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
end
