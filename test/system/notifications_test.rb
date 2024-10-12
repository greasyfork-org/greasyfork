require 'application_system_test_case'

class NotificationsTest < ApplicationSystemTestCase
  test 'no notifications' do
    user = users(:one)
    login_as(user)

    assert_notification_widget_count(0)

    visit notifications_url(user, locale: :en)
    assert_content 'No notifications yet!'
  end

  test 'a conversation notification' do
    user = users(:geoff)
    login_as(user)

    Notification.create!(user:, notification_type: Notification::NOTIFICATION_TYPE_NEW_CONVERSATION, item: conversations(:geoff_and_junior))

    visit notifications_url(user, locale: :en)
    assert_content 'Junior J. Junior, Sr. started a conversation with you: This is my message'
    assert_notification_widget_count(1)
  end

  test 'a message notification' do
    user = users(:junior)
    login_as(user)

    Notification.create!(user:, notification_type: Notification::NOTIFICATION_TYPE_NEW_MESSAGE, item: messages(:geoff_and_junior_1))

    visit notifications_url(user, locale: :en)
    assert_content 'Geoffrey sent you a message: This is my message'
  end

  test 'a report filed notification as the reported user' do
    user = users(:junior)
    login_as(user)
    report = reports(:derivative_with_same_name_report)

    Notification.create!(user:, notification_type: Notification::NOTIFICATION_TYPE_REPORT_FILED_REPORTED, item: report)

    visit notifications_url(user, locale: :en)
    assert_content 'A report was filed against MyString.'
  end

  test 'a report dismissed notification as the reported user' do
    user = users(:junior)
    login_as(user)
    report = reports(:derivative_with_same_name_report)
    report.update!(result: Report::RESULT_DISMISSED)

    Notification.create!(user:, notification_type: Notification::NOTIFICATION_TYPE_REPORT_RESOLVED_REPORTED, item: report)

    visit notifications_url(user, locale: :en)
    assert_content 'A report against MyString was dismissed by a moderator.'
  end

  test 'a report upheld notification as the reported user' do
    user = users(:junior)
    login_as(user)
    report = reports(:derivative_with_same_name_report)
    report.update!(result: Report::RESULT_UPHELD)

    Notification.create!(user:, notification_type: Notification::NOTIFICATION_TYPE_REPORT_RESOLVED_REPORTED, item: report)

    visit notifications_url(user, locale: :en)
    assert_content 'A report against MyString was upheld by a moderator.'
  end

  test 'a report fixed notification as the reported user' do
    user = users(:junior)
    login_as(user)
    report = reports(:derivative_with_same_name_report)
    report.update!(result: Report::RESULT_FIXED)

    Notification.create!(user:, notification_type: Notification::NOTIFICATION_TYPE_REPORT_RESOLVED_REPORTED, item: report)

    visit notifications_url(user, locale: :en)
    assert_content 'A report against MyString resulted in some changes and a moderator marked the issue as having been resolved.'
  end

  test 'a report dismissed notification as the reporter' do
    user = users(:junior)
    login_as(user)
    report = reports(:derivative_with_same_name_report)
    report.update!(result: Report::RESULT_DISMISSED)

    Notification.create!(user:, notification_type: Notification::NOTIFICATION_TYPE_REPORT_RESOLVED_REPORTER, item: report)

    visit notifications_url(user, locale: :en)
    assert_content 'Your report against MyString was dismissed by a moderator.'
  end

  test 'a report upheld notification as the reporter' do
    user = users(:junior)
    login_as(user)
    report = reports(:derivative_with_same_name_report)
    report.update!(result: Report::RESULT_UPHELD)

    Notification.create!(user:, notification_type: Notification::NOTIFICATION_TYPE_REPORT_RESOLVED_REPORTER, item: report)

    visit notifications_url(user, locale: :en)
    assert_content 'Your report against MyString was upheld by a moderator.'
  end

  test 'a report fixed notification as the reporter' do
    user = users(:junior)
    login_as(user)
    report = reports(:derivative_with_same_name_report)
    report.update!(result: Report::RESULT_FIXED)

    Notification.create!(user:, notification_type: Notification::NOTIFICATION_TYPE_REPORT_RESOLVED_REPORTER, item: report)

    visit notifications_url(user, locale: :en)
    assert_content 'Your report against MyString resulted in some changes and a moderator marked the issue as having been resolved.'
  end

  test 'a report rebutted notification as the reporter' do
    user = users(:junior)
    login_as(user)
    report = reports(:derivative_with_same_name_report)
    report.update!(result: nil)

    Notification.create!(user:, notification_type: Notification::NOTIFICATION_TYPE_REPORT_REBUTTED_REPORTER, item: report)

    visit notifications_url(user, locale: :en)
    assert_content 'Your report against MyString received a reply from the reported user. A moderator will review your report and this reply.'
  end

  test 'a new comment notification' do
    user = users(:junior)
    login_as(user)
    comment = comments(:non_script_comment)

    Notification.create!(user:, notification_type: Notification::NOTIFICATION_TYPE_NEW_COMMENT, item: comment)

    visit notifications_url(user, locale: :en)
    assert_content "Timmy O'Toole posted a comment on discussing something"
  end

  test 'a new script discussion notification' do
    user = users(:junior)
    login_as(user)
    comment = comments(:script_comment)

    Notification.create!(user:, notification_type: Notification::NOTIFICATION_TYPE_NEW_COMMENT, item: comment)

    visit notifications_url(user, locale: :en)
    assert_content 'Geoffrey posted a discussion on your script MyString'
  end

  test 'mark all read' do
    user = users(:geoff)
    login_as(user)

    Notification.create!(user:, notification_type: Notification::NOTIFICATION_TYPE_NEW_CONVERSATION, item: conversations(:geoff_and_junior))

    visit notifications_url(user, locale: :en)
    assert_content 'Junior J. Junior, Sr. started a conversation with you: This is my message'
    assert_notification_widget_count(1)

    assert_difference -> { Notification.unread.count } => -1 do
      click_link 'Mark all read'
      assert_notification_widget_count(0)
    end
  end

  test 'a mention notification' do
    user = users(:junior)
    login_as(user)
    comment = comments(:non_script_comment)

    Notification.create!(user:, notification_type: Notification::NOTIFICATION_TYPE_MENTION, item: comment)

    visit notifications_url(user, locale: :en)
    assert_content "Timmy O'Toole mentioned you in discussing something"
  end

  test 'a consecutive bad ratings notification' do
    script = scripts(:one)
    user = script.users.first
    login_as(user)

    Notification.create!(user:, notification_type: Notification::NOTIFICATION_TYPE_CONSECUTIVE_BAD_RATINGS, item: script)

    visit notifications_url(user, locale: :en)
    assert_content 'MyString has received bad reviews and is in danger of being removed. Fix your script or respond to the reviews to ensure it stays active.'
  end

  def assert_notification_widget_count(count)
    if count == 0
      assert_no_selector('.notification-widget')
    else
      assert_selector('.notification-widget', text: count)
    end
  end
end
