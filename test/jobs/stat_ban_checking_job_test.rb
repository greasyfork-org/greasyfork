require 'test_helper'
require 'google_analytics'

class StatBanCheckingJobTest < ActiveSupport::TestCase
  test 'no exceptions' do
    assert_no_error_reported do
      GoogleAnalytics.expects(:report_installs).returns({}).at_least_once
      StatBanCheckingJob.perform_inline
    end
  end
end
