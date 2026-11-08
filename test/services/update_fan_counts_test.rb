require 'test_helper'

class UpdateFanCountsTest < ActiveSupport::TestCase
  test 'runs' do
    assert_nothing_raised { UpdateFanCounts.new.perform }
  end
end
