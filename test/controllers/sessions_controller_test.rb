require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test 'omniauth failure rejects protocol-relative redirect origin' do
    get '/en/auth/github/callback',
        params: { failure: '1', origin: 'http:////evil.example/path' }

    assert_redirected_to new_user_session_path(locale: :en)
  end

  test 'omniauth failure allows local redirect origin' do
    get '/en/auth/github/callback',
        params: { failure: '1', origin: '/en/scripts' }

    assert_redirected_to '/en/scripts'
  end

  test 'omniauth failure falls back when redirect origin has an empty path' do
    get '/en/auth/github/callback',
        params: { failure: '1', origin: 'https://evil.example' }

    assert_redirected_to new_user_session_path(locale: :en)
  end

  test 'omniauth failure falls back when redirect origin has a nil path' do
    get '/en/auth/github/callback',
        params: { failure: '1', origin: 'mailto:evil@example.com' }

    assert_redirected_to new_user_session_path(locale: :en)
  end
end
