require 'test_helper'
require 'public_http_fetcher'

class PublicHttpFetcherTest < ActiveSupport::TestCase
  test 'maps blocked destinations to fetch errors' do
    SsrfFilter.expects(:get).raises(SsrfFilter::PrivateIPAddress, 'private address')

    error = assert_raises(PublicHttpFetcher::FetchError) do
      PublicHttpFetcher.get('http://127.0.0.1/source.user.js')
    end

    assert_equal 'private address', error.message
  end

  test 'invalid URLs use a distinct error' do
    assert_raises(PublicHttpFetcher::InvalidUrl) do
      PublicHttpFetcher.get('blob:https://example.com')
    end
  end

  test 'lets SsrfFilter handle redirects and preserves timeout options' do
    response = stub(code: '200', body: 'script contents')
    SsrfFilter.expects(:get).with do |url, options|
      url == 'https://source.example/source.user.js' &&
        options[:scheme_whitelist] == ['https'] &&
        options[:http_options] == { read_timeout: 10 } &&
        !options.key?(:max_redirects) &&
        !options.key?(:allow_unfollowed_redirects)
    end.returns(response)

    assert_equal 'script contents', PublicHttpFetcher.get('https://source.example/source.user.js')
  end

  test 'allows HTTP to redirect to HTTP or HTTPS' do
    response = stub(code: '200', body: 'script contents')
    SsrfFilter.expects(:get).with do |url, options|
      url == 'http://source.example/source.user.js' &&
        options[:scheme_whitelist] == %w[http https]
    end.returns(response)

    assert_equal 'script contents', PublicHttpFetcher.get('http://source.example/source.user.js')
  end

  test '2xx responses return their body' do
    { '200' => 'OK', '201' => 'Created', '204' => nil, '299' => 'Other success' }.each do |code, body|
      SsrfFilter.stubs(:get).returns(stub(code:, body:))

      assert_equal body.to_s, PublicHttpFetcher.get('https://source.example/source.user.js')
    end
  end

  test 'non-2xx responses raise fetch errors with the HTTP status' do
    {
      '199' => 'Informational',
      '300' => 'Multiple Choices',
      '404' => 'Not Found',
      '500' => 'Internal Server Error',
    }.each do |code, message|
      response = stub(code:, body: 'response body', message:)
      SsrfFilter.stubs(:get).returns(response)

      error = assert_raises(PublicHttpFetcher::FetchError) do
        PublicHttpFetcher.get('https://source.example/missing')
      end

      assert_equal "#{code} #{message}", error.message
    end
  end
end
