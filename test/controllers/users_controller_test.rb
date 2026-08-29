require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  test 'render user as json' do
    get user_url(users(:consumer), locale: :en, format: :json, host: 'api.greasyfork.local')
    assert_response :ok
  end

  test 'render users as json' do
    stub_es(User)
    get users_url(locale: :en, format: :json, host: 'api.greasyfork.local')
    assert_response :ok
  end

  test 'render users as jsonp' do
    stub_es(User)
    get users_url(locale: :en, format: :jsonp, host: 'api.greasyfork.local')
    assert_response :ok
  end
end
