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
      click_on 'Post comment'
      assert_content 'this is my comment'
    end
    assert user.subscribed_to?(Discussion.last)

    click_on 'Edit'
    within '.edit-comment-form' do
      fill_in 'comment_text', with: 'this is an updated reply'
    end

    click_on 'Update comment'
    assert_content 'this is an updated reply'

    assert_difference -> { Discussion.not_deleted.count } => -1 do
      accept_confirm do
        click_on 'Delete'
      end
      assert_no_content 'this is an updated reply'
    end
  end

  test 'adding a discussion mentioning a user' do
    user = User.first
    mentioned_user1 = users(:geoff)
    mentioned_user2 = users(:junior)
    UserNotificationSetting.update_delivery_types_for_user(mentioned_user1, Notification::NOTIFICATION_TYPE_MENTION, [])
    UserNotificationSetting.update_delivery_types_for_user(mentioned_user2, Notification::NOTIFICATION_TYPE_MENTION, [])

    login_as(user, scope: :user)
    visit new_discussion_path(locale: :en)
    fill_in 'Title', with: 'discussion title'
    fill_in 'discussion_comments_attributes_0_text', with: 'Hey @Geoffrey what is up? I heard from @"Junior J. Junior, Sr." that you are named @Geoffrey!'
    choose 'Greasy Fork Feedback'
    assert_no_emails do
      assert_difference -> { Discussion.count } => 1 do
        click_on 'Post comment'
        assert_content 'Hey @Geoffrey what is up? I heard from @Junior J. Junior, Sr. that you are named @Geoffrey!'
      end
    end
    assert_selector("a[href='#{user_path(mentioned_user1, locale: :en)}']", text: '@Geoffrey', count: 2)
    assert_link '@Junior J. Junior, Sr.', href: user_path(mentioned_user2, locale: :en)

    # Even if the user is renamed, the link persists.
    mentioned_user2.update!(name: 'Someone Else now')
    visit Discussion.last.url
    assert_link '@Junior J. Junior, Sr.', href: user_path(mentioned_user2, locale: :en)
  end

  test 'commenting on a discussion' do
    user = users(:geoff)
    login_as(user, scope: :user)
    discussion = discussions(:non_script_discussion)
    visit discussion.url
    fill_in 'comment_text', with: 'this is a reply'
    check 'Notify me of any replies'

    assert_difference -> { Comment.count } => 1 do
      click_on 'Post reply'
      assert_content 'this is a reply'
    end

    assert user.subscribed_to?(discussion)

    click_on 'Edit'
    within '.edit-comment-form' do
      fill_in 'comment_text', with: 'this is an updated reply'
    end
    assert_difference -> { Comment.count } => 0 do
      click_on 'Update comment'
      assert_content 'this is an updated reply'
    end

    within '.post-reply' do
      fill_in 'comment_text', with: 'this is an another reply'
      uncheck 'Notify me of any replies'
    end

    assert_difference -> { Comment.count } => 1 do
      click_on 'Post reply'
      assert_content 'this is an another reply'
    end

    assert_not user.subscribed_to?(discussion)

    assert_difference -> { Comment.not_deleted.count } => -1 do
      accept_confirm do
        within "#comment-#{Comment.last.id}" do
          click_on 'Delete'
        end
      end
      assert_no_content 'this is an another reply'
    end
  end

  test 'quoting' do
    user = User.first
    login_as(user, scope: :user)
    discussion = discussions(:non_script_discussion)
    visit discussion.url
    within '.discussion-header + .comment' do
      click_on 'Quote'
    end
    assert_field('comment_text', with: "<blockquote><p>this is a test discussion</p></blockquote>\n\n")
  end

  test 'subscribing to a discussion' do
    user = User.first
    login_as(user, scope: :user)
    discussion = discussions(:non_script_discussion)
    visit discussion.url
    assert_difference -> { DiscussionSubscription.count } => 1 do
      click_on 'Subscribe'
      assert_selector 'a', text: 'Unsubscribe'
    end
    assert_difference -> { DiscussionSubscription.count } => -1 do
      click_on 'Unsubscribe'
      assert_selector 'a', text: 'Subscribe'
    end
  end

  test 'adding a discussion with attachments' do
    user = User.first
    login_as(user, scope: :user)
    visit new_discussion_path(locale: :en)
    fill_in 'Title', with: 'discussion title'
    fill_in 'discussion_comments_attributes_0_text', with: 'this is my comment'
    choose 'Greasy Fork Feedback'
    attach_file 'Add:', [Rails.public_path.join('images/blacklogo16.png'), Rails.public_path.join('images/blacklogo32.png')]

    assert_difference -> { Discussion.count } => 1 do
      click_on 'Post comment'
      assert_content 'this is my comment'
      assert_selector '.user-screenshots img', count: 2
    end

    click_on 'Edit'
    assert_selector '.comment-screenshot-control img', count: 2
    within '.edit-comment-form' do
      fill_in 'comment_text', with: 'this is an updated reply'
    end
    within '.remove-attachment:first-child' do
      check 'Remove'
    end

    click_on 'Update comment'
    assert_content 'this is an updated reply'
    assert_selector '.user-screenshots img', count: 1
  end

  test 'locale detection' do
    Greasyfork::Application.config.enable_detect_locale = true
    DetectLanguage.expects(:detect_code).with("discussion title\nthis is my comment").returns('fr')

    user = User.first
    login_as(user, scope: :user)
    visit new_discussion_path(locale: :en)
    fill_in 'Title', with: 'discussion title'
    fill_in 'discussion_comments_attributes_0_text', with: 'this is my comment'
    choose 'Greasy Fork Feedback'
    assert_difference -> { Discussion.count } => 1 do
      click_on 'Post comment'
      assert_content 'this is my comment'
    end

    assert_equal locales(:french), Discussion.last.locale
  ensure
    Greasyfork::Application.config.enable_detect_locale = false
  end

  test 'preventing comments that format to blank' do
    user = User.first
    login_as(user, scope: :user)
    visit new_discussion_path(locale: :en)
    fill_in 'Title', with: 'discussion title'
    fill_in 'discussion_comments_attributes_0_text', with: '<script>alert("xss")</script>'
    choose 'Greasy Fork Feedback'
    click_on 'Post comment'
    assert_content "text can't be blank"
  end

  test 'preventing comments that format to blank a different way' do
    user = User.first
    login_as(user, scope: :user)
    visit new_discussion_path(locale: :en)
    fill_in 'Title', with: 'discussion title'
    fill_in 'discussion_comments_attributes_0_text', with: "<script>alert(\"xss\")</script>\n<script>alert(\"xss\")</script>"
    choose 'Greasy Fork Feedback'
    click_on 'Post comment'
    assert_content "text can't be blank"
  end
end
