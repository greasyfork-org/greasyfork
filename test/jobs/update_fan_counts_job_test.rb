require 'test_helper'

class UpdateFanCountsJobTest < ActiveSupport::TestCase
  test 'runs' do
    assert_nothing_raised { UpdateFanCountsJob.new.perform }
  end
end
