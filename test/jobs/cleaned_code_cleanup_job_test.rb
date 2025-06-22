require 'test_helper'

class CleanedCodeCleanedJobTest < ActiveSupport::TestCase
  test 'it works' do
    assert_nothing_raised do
      CleanedCodeCleanupJob.perform_inline
    end
  end
end
