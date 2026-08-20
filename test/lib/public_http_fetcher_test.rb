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

  test 'preserves OpenURI HTTP errors' do
    response = stub(code: '404', body: 'missing', message: 'Not Found')
    SsrfFilter.stubs(:get).returns(response)

    error = assert_raises(OpenURI::HTTPError) do
      PublicHttpFetcher.get('https://source.example/missing')
    end

    assert_equal '404 Not Found', error.message
  end
end
