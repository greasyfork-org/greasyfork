require 'test_helper'

class ApiDomainTest < ActionDispatch::IntegrationTest
  test 'render scripts as json' do
    stub_es(Script)
    get scripts_url(locale: :en, format: :json, domain: 'api.greasyfork.local')
    assert_response :ok
  end

  test 'do not render scripts as html' do
    stub_es(Script)
    get scripts_url(locale: :en, domain: 'api.greasyfork.local')
    assert_response :not_acceptable
  end
end
