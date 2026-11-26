require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    OmniAuth.config.stubs(:logger).returns(Rails.logger)
  end

  test 'return locations are limited by bytes and oversized locations clear an older location' do
    valid_location = "/#{'a' * 511}"
    get new_user_session_path(locale: :en), params: { return_to: valid_location }
    assert_equal valid_location, request.session[:user_return_to]

    get new_user_session_path(locale: :en), params: { return_to: "/#{'a' * 512}" }
    assert_nil request.session[:user_return_to]
    assert_response :success
  end

  test 'github request bounds the stored referer and request parameters' do
    OmniAuth.config.stubs(:allowed_hosts).returns(['www.example.com'])
    location = "/#{'a' * 511}"
    get new_user_session_path(locale: :en), params: { return_to: location }
    token = response.parsed_body.at_css('meta[name="csrf-token"]')['content']

    post '/auth/github', params: { authenticity_token: token, extra: 'a' * 4000 },
                         headers: { 'HTTP_REFERER' => "http://www.example.com/en/users/sign_in?return_to=#{location}" }

    assert_match %r{\Ahttps://github\.com/}, response.location
    assert_equal location, request.session[:user_return_to]
    assert_nil request.session['omniauth.params']
    sign_in = request.session['omniauth.sign_ins'].values.last
    assert_nil sign_in['origin']
  end

  test 'github request discards an oversized return location from an existing session' do
    env = Rack::MockRequest.env_for('/auth/github', method: 'POST')
    env['rack.session'] = { user_return_to: "/#{'a' * 1024}", 'omniauth.params' => {} }

    OmniAuth.config.before_request_phase.call(env)

    assert_nil env['rack.session'][:user_return_to]
  end

  test 'github request preserves a short origin and rejects oversized login fields' do
    OmniAuth.config.stubs(:allowed_hosts).returns(['www.example.com'])
    get new_user_session_path(locale: :en)
    token = response.parsed_body.at_css('meta[name="csrf-token"]')['content']

    post '/auth/github', params: { authenticity_token: token, chosen_name: 'name' },
                         headers: { 'HTTP_REFERER' => 'http://www.example.com/en/scripts' }
    assert_match %r{\Ahttps://github\.com/}, response.location
    assert_equal 'name', request.session[:chosen_name]
    assert_equal 'http://www.example.com/en/scripts', request.session['omniauth.sign_ins'].values.last['origin']
    assert_nil request.session['omniauth.params']
    assert_equal({ 'chosen_name' => 'name' }, request.session['omniauth.sign_ins'].values.last['params'])

    post '/auth/github', params: { authenticity_token: token, chosen_name: 'a' * 4000 }
    assert_match %r{/auth/failure}, response.location
    assert_not_equal 'a' * 4000, request.session[:chosen_name]
  end

  test 'github request keeps supported parameters within their application limits' do
    OmniAuth.config.stubs(:allowed_hosts).returns(['www.example.com'])
    get new_user_session_path(locale: :en)
    token = response.parsed_body.at_css('meta[name="csrf-token"]')['content']
    name = "\u{1F600}" * 50

    post '/auth/github', params: { authenticity_token: token, chosen_name: name, remember_me: '1', locale_id: '19', extra: 'ignored' }

    assert_match %r{\Ahttps://github\.com/}, response.location
    assert_nil request.session['omniauth.params']
    assert_equal name, request.session[:chosen_name]
    assert_equal({ 'remember_me' => '1', 'locale_id' => '19' }, request.session['omniauth.sign_ins'].values.last['params'])

    post '/auth/github', params: { authenticity_token: token, chosen_name: "#{name}a" }
    assert_match %r{/auth/failure}, response.location

    [{ locale_id: '1' * 7 }, { locale_id: 'invalid' }, { remember_me: '11' }].each do |invalid|
      post '/auth/github', params: { authenticity_token: token }.merge(invalid)
      assert_match %r{/auth/failure}, response.location
    end
  end

  test 'repeated github requests fit alongside a maximum size return location' do
    OmniAuth.config.stubs(:allowed_hosts).returns(['www.example.com'])
    get new_user_session_path(locale: :en), params: { return_to: "/#{'a' * 511}" }
    token = response.parsed_body.at_css('meta[name="csrf-token"]')['content']
    referer = "http://www.example.com/#{'a' * 100}"

    3.times do
      post '/auth/github', params: { authenticity_token: token, chosen_name: "\u{1F600}" * 50, locale_id: '1' * 6, remember_me: '1',
                                     return_to: "/#{'a' * 509}", origin: "/#{'a' * 125}" },
                           headers: { 'HTTP_REFERER' => referer }
      assert_match %r{\Ahttps://github\.com/}, response.location
      assert_operator cookies['_greasyfork_session'].bytesize, :<=, 4096 - '_greasyfork_session'.bytesize
    end
  end

  test 'remembered parameters from several github requests fit in the session' do
    OmniAuth.config.stubs(:allowed_hosts).returns(['www.example.com'])
    get new_user_session_path(locale: :en), params: { return_to: "/#{'a' * 511}" }
    token = response.parsed_body.at_css('meta[name="csrf-token"]')['content']
    referer = "http://www.example.com/#{'a' * 100}"

    ['a' * 31, 'a' * 31, 'a' * 31, "\u{1F600}" * 50].each do |name|
      post '/auth/github', params: { authenticity_token: token, chosen_name: name, locale_id: '1', remember_me: '1' },
                           headers: { 'HTTP_REFERER' => referer }
      assert_match %r{\Ahttps://github\.com/}, response.location
      assert_operator cookies['_greasyfork_session'].bytesize, :<=, 4096 - '_greasyfork_session'.bytesize
    end
  end

  test 'github sign-in returns to a retained location after the callback' do
    OmniAuth.config.stubs(:allowed_hosts).returns(['www.example.com'])
    user = users(:consumer)
    user.update_columns(encrypted_password: nil)
    Identity.create!(user:, provider: 'github', uid: '123', syncing: false)
    OmniAuth::Strategies::GitHub.any_instance.stubs(:fetch_access_token).returns(Object.new)
    OmniAuth::Strategies::GitHub.any_instance.stubs(:auth_hash).returns(
      OmniAuth::AuthHash.new(provider: 'github', uid: '123', info: { nickname: user.name, email: user.email })
    )

    get new_user_session_path(locale: :en), params: { return_to: '/en/scripts' }
    token = response.parsed_body.at_css('meta[name="csrf-token"]')['content']
    post '/auth/github', params: { authenticity_token: token, locale_id: '1' }
    state = Rack::Utils.parse_query(URI.parse(response.location).query)['state']

    get '/auth/github/callback', params: { state:, code: 'test' }
    assert_redirected_to '/en/scripts'
    assert_equal({ 'locale_id' => '1' }, request.env['omniauth.params'])
  end

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
