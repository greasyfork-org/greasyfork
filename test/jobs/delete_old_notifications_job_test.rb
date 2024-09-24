require 'test_helper'

class DeleteOldNotificationsJobTest < ActiveSupport::TestCase
  test "when it's not old" do
    Notification.create!(item: Comment.first, user: User.first, notification_type: Notification::NOTIFICATION_TYPE_NEW_COMMENT)

    assert_no_difference -> { Notification.count } do
      DeleteOldNotificationsJob.perform_inline
    end
  end

  test "when it's old" do
    Notification.create!(item: Comment.first, user: User.first, created_at: 400.days.ago, notification_type: Notification::NOTIFICATION_TYPE_NEW_COMMENT)

    assert_difference -> { Notification.count } => -1 do
      DeleteOldNotificationsJob.perform_inline
    end
  end
end
