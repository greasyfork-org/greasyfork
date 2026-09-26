require 'test_helper'

class InactiveUserNotificationJobTest < ActiveSupport::TestCase
  test 'sends inactive notifications to at most 100 users' do
    users = Array.new(100) do
      user = mock
      user.expects(:send_inactive_notification_email!)
      user
    end
    inactive_users = mock

    User.expects(:inactive_notifiable).returns(inactive_users)
    inactive_users.expects(:limit).with(100).returns(users)

    InactiveUserNotificationJob.perform_inline
  end
end
