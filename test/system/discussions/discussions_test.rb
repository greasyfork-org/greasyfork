require 'test_helper'

class DiscussionsTest < ApplicationSystemTestCase
  include ActionMailer::TestHelper

  test 'adding a discussion' do
    user = User.first
    login_as(user, scope: :user)
    visit new_discussion_path(locale: :en)
    fill_in 'Title', with: 'discussion title'
    fill_in 'discussion_comments_attributes_0_text', with: 'this is my comment'
    choose 'Greasy Fork Feedback'
    assert_difference -> { Discussion.count } => 1 do
      click_button 'Post comment'
      assert_content 'this is my comment'
    end
    assert user.subscribed_to?(Discussion.last)

    click_link 'Edit'
    within '.edit-comment-form' do
      fill_in 'comment_text', with: 'this is an updated reply'
    end

    click_button 'Update comment'
    assert_content 'this is an updated reply'

    assert_difference -> { Discussion.not_deleted.count } => -1 do
      accept_confirm do
        click_link 'Delete'
      end
      assert_no_content 'this is an updated reply'
    end
  end

  test 'adding a discussion mentioning a user' do
    user = User.first
    mentioned_user1 = users(:geoff)
    mentioned_user2 = users(:junior)
    mentioned_user1.update!(notify_on_mention: false)
    mentioned_user2.update!(notify_on_mention: false)

    login_as(user, scope: :user)
    visit new_discussion_path(locale: :en)
    fill_in 'Title', with: 'discussion title'
    fill_in 'discussion_comments_attributes_0_text', with: 'Hey @Geoffrey what is up? I heard from @"Junior J. Junior, Sr." that you are named @Geoffrey!'
    choose 'Greasy Fork Feedback'
    assert_no_emails do
      assert_difference -> { Discussion.count } => 1 do
        click_button 'Post comment'
        assert_content 'Hey @Geoffrey what is up? I heard from @"Junior J. Junior, Sr." that you are named @Geoffrey!'
      end
    end
    assert_selector("a[href='#{user_path(mentioned_user1, locale: :en)}']", text: '@Geoffrey', count: 2)
    assert_link '@"Junior J. Junior, Sr."', href: user_path(mentioned_user2, locale: :en)

    # Even if the user is renamed, the link persists.
    mentioned_user2.update!(name: 'Someone Else now')
    visit Discussion.last.url
    assert_link '@"Junior J. Junior, Sr."', href: user_path(mentioned_user2, locale: :en)
  end

  test 'adding a discussion mentioning a user with notifications' do
    user = User.first
    mentioned_user = users(:geoff)
    mentioned_user.update!(notify_on_mention: true)

    login_as(user, scope: :user)
    visit new_discussion_path(locale: :en)
    fill_in 'Title', with: 'discussion title'
    fill_in 'discussion_comments_attributes_0_text', with: 'Hey @Geoffrey'
    choose 'Greasy Fork Feedback'
    perform_enqueued_jobs(only: CommentNotificationJob) do
      assert_difference -> { Discussion.count } => 1 do
        click_button 'Post comment'
        assert_content 'Hey @Geoffrey'
      end
    end
    assert_enqueued_email_with ForumMailer, :comment_on_mentioned, args: [mentioned_user, Comment.last]
  end

  test 'commenting on a discussion' do
    user = users(:geoff)
    login_as(user, scope: :user)
    discussion = discussions(:non_script_discussion)
    visit discussion.url
    fill_in 'comment_text', with: 'this is a reply'
    check 'Notify me of any replies'

    assert_difference -> { Comment.count } => 1 do
      click_button 'Post reply'
      assert_content 'this is a reply'
    end

    assert user.subscribed_to?(discussion)

    click_link 'Edit'
    within '.edit-comment-form' do
      fill_in 'comment_text', with: 'this is an updated reply'
    end
    assert_difference -> { Comment.count } => 0 do
      click_button 'Update comment'
      assert_content 'this is an updated reply'
    end

    within '.post-reply' do
      fill_in 'comment_text', with: 'this is an another reply'
      uncheck 'Notify me of any replies'
    end

    assert_difference -> { Comment.count } => 1 do
      click_button 'Post reply'
      assert_content 'this is an another reply'
    end

    assert_not user.subscribed_to?(discussion)

    assert_difference -> { Comment.not_deleted.count } => -1 do
      accept_confirm do
        within "#comment-#{Comment.last.id}" do
          click_link 'Delete'
        end
      end
      assert_no_content 'this is an another reply'
    end
  end

  test 'commenting with mention with notify' do
    user = User.first
    login_as(user, scope: :user)

    mentioned_user = users(:geoff)
    mentioned_user.update!(notify_on_mention: true)

    perform_enqueued_jobs(only: CommentNotificationJob) do
      discussion = discussions(:non_script_discussion)
      visit discussion.url
      fill_in 'comment_text', with: 'Hey @Geoffrey'
      click_button 'Post reply'
      assert_content 'Hey @Geoffrey'
    end

    assert_enqueued_email_with ForumMailer, :comment_on_mentioned, args: [mentioned_user, Comment.last]
  end

  test 'quoting' do
    user = User.first
    login_as(user, scope: :user)
    discussion = discussions(:non_script_discussion)
    visit discussion.url
    within '.discussion-header + .comment' do
      click_link 'Quote'
    end
    assert_field('comment_text', with: "<blockquote>this is a test discussion</blockquote>\n\n")
  end

  test 'subscribing to a discussion' do
    user = User.first
    login_as(user, scope: :user)
    discussion = discussions(:non_script_discussion)
    visit discussion.url
    assert_difference -> { DiscussionSubscription.count } => 1 do
      click_link 'Subscribe'
      assert_selector 'a', text: 'Unsubscribe'
    end
    assert_difference -> { DiscussionSubscription.count } => -1 do
      click_link 'Unsubscribe'
      assert_selector 'a', text: 'Subscribe'
    end
  end
end
