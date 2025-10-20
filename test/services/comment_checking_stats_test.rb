require 'test_helper'

class CommentCheckingStatsTest < ActiveSupport::TestCase
  test 'no exceptions' do
    service = CommentCheckingStats.new
    assert_nothing_raised do
      service.run
    end
  end
end
