require 'test_helper'

class UserTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    EmailAddress.stubs(:valid?).returns(true)
  end

  test 'deleting scripts where they are the sole author' do
    user = User.find(1)
    assert_equal user, Script.find(1).users.first
    user.destroy!
    assert_nil Script.find_by(id: 1)
  end

  test 'not deleting scripts where they are not the sole author' do
    user = User.find(1)
    assert_equal user, Script.find(2).users.first
    user.destroy!
    assert_not_nil Script.find_by(id: 2)
  end

  [:geoff, :junior].each do |participant|
    test "deleting #{participant} deletes their conversations and related records" do
      conversation = conversations(:geoff_and_junior)
      message = messages(:geoff_and_junior_1)
      other_user = users((participant == :geoff) ? :junior : :geoff)
      conversation_notification = Notification.create!(user: other_user, item: conversation, notification_type: :new_conversation)
      message_notification = Notification.create!(user: other_user, item: message, notification_type: :new_message)
      report = Report.create!(item: message, reason: Report::REASON_SPAM, reporter: other_user)
      unrelated = Conversation.create!(starting_user: users(:one), users: [users(:one), users(:mod)])

      users(participant).destroy!

      assert_not Conversation.exists?(conversation.id)
      assert_not Message.exists?(message.id)
      assert_not Notification.exists?(conversation_notification.id)
      assert_not Notification.exists?(message_notification.id)
      assert_not Report.exists?(report.id)
      assert Conversation.exists?(unrelated.id)
    end
  end

  test 'pending message notifications are discarded after account deletion' do
    message = messages(:geoff_and_junior_1)
    MessageNotificationJob.perform_later(message)

    users(:geoff).destroy!

    assert_nothing_raised { perform_enqueued_jobs(only: MessageNotificationJob) }
  end

  test 'deleting a banned user' do
    user = User.find(1)
    user.update!(banned_at: Time.current)
    assert_difference -> { BannedEmailHash.count } => 1 do
      assert_changes -> { User.email_previously_banned_and_deleted?(user.email) }, from: false, to: true do
        user.destroy!
      end
    end
  end

  test 'banning related users propagates comment deletion' do
    user = users(:one)
    related_user = users(:geoff)
    related_user.update_columns(canonical_email: user.canonical_email)
    related_comment = comments(:script_comment)
    SpammyEmailDomainBannerJob.stubs(:perform_async)

    user.ban!(moderator: users(:mod), delete_comments: true, delete_scripts: false)

    assert related_user.reload.banned?
    assert related_comment.reload.soft_deleted?
  end

  test 'banning related users does not derive comment deletion from script deletion' do
    user = users(:one)
    related_user = users(:geoff)
    related_user.update_columns(canonical_email: user.canonical_email)
    related_comment = comments(:script_comment)
    SpammyEmailDomainBannerJob.stubs(:perform_async)

    user.ban!(moderator: users(:mod), delete_comments: false, delete_scripts: true)

    assert related_user.reload.banned?
    assert_not related_comment.reload.soft_deleted?
  end

  test 'blocked_from_reporting_until with no reports' do
    user = users(:one)
    assert_nil user.blocked_from_reporting_until
  end

  test 'blocked_from_reporting_until with reports' do
    user = users(:one)
    4.times { Report.create!(reporter: user, result: Report::RESULT_DISMISSED, item: Script.first, reason: Report::REASON_SPAM) }
    assert_nil user.blocked_from_reporting_until
    Report.create!(reporter: user, result: Report::RESULT_DISMISSED, item: Script.first, reason: Report::REASON_SPAM)
    assert_not_nil user.blocked_from_reporting_until
    Report.last.update!(result: Report::RESULT_UPHELD)
    assert_nil user.blocked_from_reporting_until
  end

  test 'invisible characters are OK if they do not match an existing user' do
    new_user = User.new(name: "i like weird\u2064chars", email: 'test@aol.com', password: 'password')
    assert new_user.valid?, new_user.errors.messages
  end

  test 'invisible characters are not OK if they match an existing user' do
    existing_user = users(:one)
    new_user = User.new(name: 'foo', email: 'test@aol.com', password: 'password')
    assert new_user.valid?, new_user.errors.messages
    new_user.name = existing_user.name
    new_user.name.insert(2, "\u2064")
    assert_not new_user.valid?
  end

  test 'reserved unicode characters are not OK' do
    new_user = User.new(name: "i like weird\ufff7chars", email: 'test@myexample.com', password: 'password')
    assert_not new_user.valid?, new_user.errors.messages
  end

  test '#search_data' do
    assert_not_empty User.first.search_data
  end
end
