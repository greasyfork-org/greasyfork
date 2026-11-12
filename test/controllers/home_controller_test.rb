require 'test_helper'

class HomeControllerTest < ActionDispatch::IntegrationTest
  test 'URL markup preview reports HTTP errors' do
    get help_allowed_markup_path(locale: :en)
    token = response.parsed_body.at_css('meta[name="csrf-token"]')['content']
    http_response = stub(code: '404', message: 'Not Found')
    SsrfFilter.expects(:get).returns(http_response)

    post preview_markup_url(locale: :en), params: { url: 'true', text: 'https://example.com/missing', markup: 'html', authenticity_token: token }

    assert_response :success
    assert_includes response.body, '404 Not Found'
  end
end
