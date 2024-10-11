require 'application_system_test_case'

module Discussions
  class NotificationsTest < ApplicationSystemTestCase
    include ActionMailer::TestHelper

    test 'adding a discussion mentioning a user with notifications' do
      user = User.first
      mentioned_user = users(:geoff)
      UserNotificationSetting.update_delivery_types_for_user(mentioned_user, Notification::NOTIFICATION_TYPE_MENTION, UserNotificationSetting::ALL_DELIVERY_TYPES)

      login_as(user, scope: :user)
      visit new_discussion_path(locale: :en)
      fill_in 'Title', with: 'discussion title'
      fill_in 'discussion_comments_attributes_0_text', with: 'Hey @Geoffrey'
      choose 'Greasy Fork Feedback'
      perform_enqueued_jobs(only: CommentNotificationJob) do
        assert_difference -> { Notification.count } => 1 do
          assert_difference -> { Discussion.count } => 1 do
            click_on 'Post comment'
            assert_content 'Hey @Geoffrey'
          end
        end
      end
      assert_enqueued_email_with ForumMailer, :comment_on_mentioned, args: [mentioned_user, Comment.last]
    end

    test 'commenting on a subscribed discussion' do
      user = User.first
      discussion = discussions(:non_script_discussion)
      login_as(user, scope: :user)

      subscribed_user = users(:geoff)
      DiscussionSubscription.create!(user: subscribed_user, discussion:)

      assert_difference -> { Notification.count } => 1 do
        perform_enqueued_jobs(only: CommentNotificationJob) do
          visit discussion.url
          fill_in 'comment_text', with: 'Hey buddy'
          click_on 'Post reply'
          assert_content 'Hey buddy'
        end
      end

      assert_enqueued_email_with ForumMailer, :comment_on_subscribed, args: [subscribed_user, Comment.last]
    end

    test 'commenting with mention with notify' do
      user = User.first
      login_as(user, scope: :user)

      mentioned_user = users(:geoff)
      UserNotificationSetting.update_delivery_types_for_user(mentioned_user, Notification::NOTIFICATION_TYPE_MENTION, UserNotificationSetting::ALL_DELIVERY_TYPES)

      perform_enqueued_jobs(only: CommentNotificationJob) do
        assert_difference -> { Notification.count } => 1 do
          discussion = discussions(:non_script_discussion)
          visit discussion.url
          fill_in 'comment_text', with: 'Hey @Geoffrey'
          click_on 'Post reply'
          assert_content 'Hey @Geoffrey'
        end
      end

      assert_enqueued_email_with ForumMailer, :comment_on_mentioned, args: [mentioned_user, Comment.last]
    end

    test 'marking notifications as read' do
      user = users(:junior)
      login_as(user)
      comment = comments(:script_comment)

      Notification.create!(user:, notification_type: Notification::NOTIFICATION_TYPE_NEW_COMMENT, item: comment)

      assert_difference -> { Notification.unread.count } => -1 do
        visit comment.url
        assert_content 'this is a test discussion'
      end
    end

    test 'adding a discussion on a script subscribes the author if the setting is true' do
      user = users(:consumer)
      login_as(user, scope: :user)

      script = Script.first
      author = script.users.first
      author.update!(subscribe_on_script_discussion: true)

      visit feedback_script_url(script, locale: :en)
      fill_in 'discussion_comments_attributes_0_text', with: 'this is my comment'
      choose 'Good'
      assert_difference -> { Discussion.count } => 1 do
        click_on 'Post comment'
        assert_content 'this is my comment'
      end

      perform_enqueued_jobs(only: CommentNotificationJob)
      assert author.subscribed_to?(Discussion.last)
      assert_enqueued_email_with ForumMailer, :comment_on_script, args: [author, Comment.last]
    end

    test 'adding a discussion on a script does not subscribe the author if the setting is false' do
      user = users(:consumer)
      login_as(user, scope: :user)

      script = Script.first
      author = script.users.first
      author.update!(subscribe_on_script_discussion: false)

      visit feedback_script_url(script, locale: :en)
      fill_in 'discussion_comments_attributes_0_text', with: 'this is my comment'
      choose 'Good'
      assert_difference -> { Discussion.count } => 1 do
        click_on 'Post comment'
        assert_content 'this is my comment'
      end

      perform_enqueued_jobs(only: CommentNotificationJob)
      assert_not author.subscribed_to?(Discussion.last)
    end
  end
end
