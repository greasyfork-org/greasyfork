require 'test_helper'

class CleanedCodeCleanedJobTest < ActiveSupport::TestCase
  test 'it works' do
    CleanedCodeCleanupJob.perform_inline
  end
end
