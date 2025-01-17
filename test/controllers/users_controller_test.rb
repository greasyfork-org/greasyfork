require 'test_helper'

class ScriptsControllerTest < ActionDispatch::IntegrationTest
  test 'render user as json' do
    get user_url(users(:consumer), locale: :en, format: :json, host: 'api.greasyfork.local')
    assert_response :ok
  end
end
