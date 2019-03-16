require 'test_helper'

class ScriptsControllerTest < ActionDispatch::IntegrationTest
  test "render script as json" do
    get script_url(Script.first, locale: :en, format: :json)
    assert_response 200
  end
end