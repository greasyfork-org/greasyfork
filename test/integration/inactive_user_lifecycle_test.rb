require 'test_helper'

class InactiveUserLifecycleTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    travel_to(Time.zone.local(2026, 9, 26, 12))
  end

  test 'user is retained until the notification period ends' do
    user = create_inactive_user
    notify_user(user)

    travel_to(user.inactive_notification_sent_at + InactiveUser::DELETE_AFTER_NOTIFICATION - 1.second) do
      InactiveUserDeleteJob.perform_inline
    end

    assert User.exists?(user.id)
  end

  test 'user who signs in during the notification period is retained' do
    user = create_inactive_user
    notify_user(user)
    user.update!(current_sign_in_at: Time.current)

    travel_to(user.inactive_notification_sent_at + InactiveUser::DELETE_AFTER_NOTIFICATION + 1.second) do
      InactiveUserDeleteJob.perform_inline
    end

    assert User.exists?(user.id)
  end

  test 'user is deleted after the notification period if they have not signed in' do
    user = create_inactive_user
    notify_user(user)

    travel_to(user.inactive_notification_sent_at + InactiveUser::DELETE_AFTER_NOTIFICATION + 1.second) do
      InactiveUserDeleteJob.perform_inline
    end

    assert_not User.exists?(user.id)
  end

  test 'users with sign-in or content activity are neither notified nor deleted' do
    signed_in_user = create_inactive_user
    signed_in_user.update!(current_sign_in_at: 1.day.ago)

    scripted_user = create_inactive_user
    scripts(:one).authors.create!(user: scripted_user)

    commenting_user = create_inactive_user
    comments(:non_script_comment_2).update!(poster: commenting_user)

    active_users = [signed_in_user, scripted_user, commenting_user]

    assert_no_enqueued_emails do
      InactiveUserNotificationJob.perform_inline
    end
    assert(active_users.all? { |user| user.reload.inactive_notification_sent_at.nil? })

    InactiveUserDeleteJob.perform_inline

    assert(active_users.all? { |user| User.exists?(user.id) })
  end

  private

  def create_inactive_user
    identifier = SecureRandom.hex(8)
    user = User.create!(
      email: "inactive-#{identifier}@example.com",
      password: 'password123',
      name: "Inactive test user #{identifier}"
    )
    user.update!(current_sign_in_at: 6.years.ago)
    user
  end

  def notify_user(user)
    assert_enqueued_email_with InactiveUserMailer, :notify, args: [user] do
      InactiveUserNotificationJob.perform_inline
    end
    user.reload
  end
end
