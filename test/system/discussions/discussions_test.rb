require 'test_helper'

class DiscussionsTest < ApplicationSystemTestCase
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
  end

  test 'commenting on a discussion' do
    user = User.first
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
