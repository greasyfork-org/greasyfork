require "test_helper"
require 'minitest/around/unit'
require 'webdrivers/chromedriver'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400], options: { args: [ENV['HEADED'] == '1' ? nil : "headless", "disable-gpu", "no-sandbox", "disable-dev-shm-usage"].compact }
  include Warden::Test::Helpers
end

Capybara.server = :webrick
