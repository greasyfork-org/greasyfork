require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400], options: { args: ["headless", "disable-gpu", "no-sandbox", "disable-dev-shm-usage"] }
end

Capybara.server = :webrick
