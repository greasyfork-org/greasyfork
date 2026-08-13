require 'test_helper'
require 'public_http_fetcher'

class PublicHttpFetcherTest < ActiveSupport::TestCase
  test 'maps blocked destinations to argument errors' do
    SsrfFilter.expects(:get).raises(SsrfFilter::PrivateIPAddress, 'private address')

    error = assert_raises(ArgumentError) do
      PublicHttpFetcher.get('http://127.0.0.1/source.user.js')
    end

    assert_equal 'private address', error.message
  end

  test 'preserves redirect and timeout options' do
    response = stub(code: '200', body: 'script contents')
    SsrfFilter.expects(:get).with do |url, options|
      url == 'https://source.example/source.user.js' &&
        options[:allow_unfollowed_redirects] == true &&
        options[:max_redirects] == 0 &&
        options[:http_options] == { read_timeout: 10 }
    end.returns(response)

    assert_equal 'script contents', PublicHttpFetcher.get('https://source.example/source.user.js')
  end

  test 'resolves relative redirects and blocks HTTPS downgrade' do
    redirect = stub(code: '302', body: '', message: 'Found')
    redirect.stubs(:[]).with('location').returns('next.user.js')
    SsrfFilter.expects(:get).with('https://source.example/path/source.user.js', anything).returns(redirect)
    SsrfFilter.expects(:get).with('https://source.example/path/next.user.js', anything).returns(stub(code: '200', body: 'script contents'))

    assert_equal 'script contents', PublicHttpFetcher.get('https://source.example/path/source.user.js')

    downgrade = stub(code: '302', body: '', message: 'Found')
    downgrade.stubs(:[]).with('location').returns('http://source.example/source.user.js')
    SsrfFilter.stubs(:get).returns(downgrade)

    assert_raises(ArgumentError) do
      PublicHttpFetcher.get('https://source.example/source.user.js')
    end
  end

  test 'preserves OpenURI HTTP errors' do
    response = stub(code: '404', body: 'missing', message: 'Not Found')
    response.stubs(:[]).with('location').returns(nil)
    SsrfFilter.stubs(:get).returns(response)

    error = assert_raises(OpenURI::HTTPError) do
      PublicHttpFetcher.get('https://source.example/missing')
    end

    assert_equal '404 Not Found', error.message
  end
end
