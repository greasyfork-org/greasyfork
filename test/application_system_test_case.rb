require 'test_helper'
require 'minitest/around/unit'
require 'webdrivers/chromedriver'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :headless_chrome
  include Warden::Test::Helpers

  def allow_js_error(pattern)
    pre_messages = page.driver.browser.manage.logs.get(:browser).map(&:message).reject { |message| js_error_ignored?(message) }
    raise pre_messages.first if pre_messages.any?

    yield
    post_messages = page.driver.browser.manage.logs.get(:browser).map(&:message).reject { |m| pattern.is_a?(Regexp) ? pattern.match?(m) : m.include?(pattern) }.reject { |message| js_error_ignored?(message) }
    raise post_messages.first if post_messages.any?
  end

  def js_error_ignored?(err)
    err.include?('`SameSite=None` but without `Secure`')
  end

  def assert_script_deleted_page
    allow_js_error 'Failed to load resource: the server responded with a status of 404 (Not Found)' do
      Script.stubs(:search).returns(Script.all)
      yield
      assert_content 'The script you requested has been deleted, but here are some related scripts.'
    end
  end

  teardown do
    messages = page.driver.browser.manage.logs.get(:browser)
                   .map(&:message)
                   .reject { |message| js_error_ignored?(message) }
    raise "Browser console in #{method_name}: #{messages}" if messages.any?
  end
end

Capybara.server = :puma

Capybara.register_driver :headless_chrome do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    'goog:chromeOptions' => { args: ['verbose', 'disable-gpu', 'no-sandbox', 'disable-dev-shm-usage', 'window-size=1400,1400', ENV['HEADED'] == '1' ? nil : 'headless'].compact },
    'goog:loggingPrefs' => { browser: 'ALL' }
  )

  Capybara::Selenium::Driver.new app,
                                 browser: :chrome,
                                 desired_capabilities: capabilities,
                                 clear_local_storage: true
end
