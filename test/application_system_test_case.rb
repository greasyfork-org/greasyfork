require "test_helper"
require 'minitest/around/unit'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400], options: { args: ["headless", "disable-gpu", "no-sandbox", "disable-dev-shm-usage"] }
  include Warden::Test::Helpers
end

Capybara.server = :webrick
