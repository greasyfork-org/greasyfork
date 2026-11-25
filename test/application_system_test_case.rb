if ENV['HEADED'] == '1' && ENV['XDG_DATA_DIRS_VSCODE_SNAP_ORIG'] &&
   ENV['GSETTINGS_SCHEMA_DIR']&.match?(%r{/snap/code/[^/]+/\.local/share/glib-2\.0/schemas\z})
  # VS Code's Snap schemas can prevent the system Chrome from starting on Wayland.
  ENV['XDG_DATA_DIRS'] = ENV['XDG_DATA_DIRS_VSCODE_SNAP_ORIG']
  ENV.delete('GSETTINGS_SCHEMA_DIR')
end

require 'test_helper'
require 'minitest/around/unit'
require_relative 'support/inspector_error_retry'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include InspectorErrorRetry

  driven_by :headless_chrome
  include Warden::Test::Helpers

  def allow_js_error(pattern)
    pre_messages = page.driver.browser.logs.get(:browser).map(&:message).reject { |message| js_error_ignored?(message) }
    raise pre_messages.first if pre_messages.any?

    yield
    post_messages = page.driver.browser.logs.get(:browser).map(&:message).reject { |m| pattern.is_a?(Regexp) ? pattern.match?(m) : m.include?(pattern) }.reject { |message| js_error_ignored?(message) }
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

  def assert_on_script_tab(label)
    assert_selector '#script-links .current', text: label
  end

  teardown do
    messages = page.driver.browser.logs.get(:browser)
                   .map(&:message)
                   .reject { |message| js_error_ignored?(message) }
    raise "Browser console in #{method_name}: #{messages}" if messages.any?
  end

  def after_teardown
    super
    FileUtils.rm_rf(ActiveStorage::Blob.service.root)
  end
end

Capybara.server = :puma

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Options.chrome(
    args: ['verbose', 'disable-gpu', 'no-sandbox', 'disable-dev-shm-usage', 'window-size=1400,1400', (ENV['HEADED'] == '1') ? nil : 'headless=new'].compact
  )
  # Chrome 158 breaks Capybara's session reset: https://github.com/teamcapybara/capybara/issues/2865
  options.browser_version = '157.0.8103.78'
  options.add_preference('download.default_directory', File::NULL)
  options.add_preference('profile.password_manager_leak_detection', false)

  Capybara::Selenium::Driver.new app,
                                 browser: :chrome,
                                 options:,
                                 clear_local_storage: true
end
