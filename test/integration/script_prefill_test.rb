require 'test_helper'

class ScriptPrefillTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    users(:one).update!(otp_required_for_login: true)
  end

  test 'should prefill code for new scripts' do
    sign_in users(:one)
    post '/en/script_versions/prefill', params: { script_version: { code: 'Hello, World' } }
    assert_includes @response.body, 'Hello, World'
  end

  test 'should prefill code for existing scripts' do
    script = scripts(:one)
    sign_in script.users.first
    post "/en/scripts/#{script.id}/versions/prefill", params: { script_version: { code: 'Hello, World' } }
    assert_includes @response.body, 'Hello, World'
  end
end
