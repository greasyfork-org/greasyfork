require 'test_helper'

class LibraryUsageStatisticsTest < ActiveSupport::TestCase
  test 'refresh usages does not fail' do
    assert_nothing_raised do
      LibraryUsageStatistics.refresh_usages
    end
  end
end
