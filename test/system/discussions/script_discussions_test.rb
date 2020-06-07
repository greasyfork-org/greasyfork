require 'test_helper'

class ScriptDiscussionsTest < ApplicationSystemTestCase
  test 'adding a discussion on a script' do
    user = User.first
    login_as(user, scope: :user)
    script = Script.first
    visit feedback_script_url(script, locale: :en)
    fill_in 'discussion_comments_attributes_0_text', with: 'this is my comment'
    choose 'Good'
    assert_difference -> { Discussion.count } => 1 do
      click_button 'Post comment'
      assert_content 'this is my comment'
    end
    assert_equal Discussion::RATING_GOOD, Discussion.last.rating
    click_link 'Edit'
    within '.edit-comment-form' do
      fill_in 'comment_text', with: 'this is an updated reply'
    end
    choose 'Bad'
    assert_changes -> { Discussion.last.rating }, from: Discussion::RATING_GOOD, to: Discussion::RATING_BAD do
      click_button 'Update comment'
      assert_content 'this is an updated reply'
    end
  end

  test 'commenting on a discussion' do
    user = User.first
    login_as(user, scope: :user)
    discussion = discussions(:script_discussion)
    visit feedback_script_url(discussion.script, locale: :en)
    click_link 'this is a test discussion'
    fill_in 'comment_text', with: 'this is a reply'
    assert_difference -> { Comment.count } => 1 do
      click_button 'Post reply'
      assert_content 'this is a reply'
    end

    click_link 'Edit'
    within '.edit-comment-form' do
      fill_in 'comment_text', with: 'this is an updated reply'
    end
    assert_difference -> { Comment.count } => 0 do
      click_button 'Update comment'
      assert_content 'this is an updated reply'
    end
  end

  test 'subscribing to a discussion' do
    user = User.first
    login_as(user, scope: :user)
    discussion = discussions(:script_discussion)
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
