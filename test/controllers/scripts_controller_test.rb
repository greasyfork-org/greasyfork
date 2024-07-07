require 'test_helper'

class ScriptsControllerTest < ActionDispatch::IntegrationTest
  test 'render scripts as json' do
    with_sphinx do
      get scripts_url(locale: :en, format: :json)
      assert_response :ok
    end
  end

  test 'render script as json' do
    get script_url(Script.first, locale: :en, format: :json)
    assert_response :ok
  end
end
