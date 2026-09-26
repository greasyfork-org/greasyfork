require 'test_helper'

class InactiveUserDeleteJobTest < ActiveSupport::TestCase
  test 'destroys inactive deletable users' do
    inactive_users = mock

    User.expects(:inactive_deletable).returns(inactive_users)
    inactive_users.expects(:destroy_all)

    InactiveUserDeleteJob.perform_inline
  end
end
