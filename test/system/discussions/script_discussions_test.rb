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
      click_button 'Create Discussion'
      assert_content 'this is my comment'
    end
    assert_equal Discussion::RATING_GOOD, Discussion.last.rating
  end

  test 'commenting on a discussion' do
    user = User.first
    login_as(user, scope: :user)
    discussion = discussions(:script_discussion)
    visit feedback_script_url(discussion.script, locale: :en)
    click_link 'this is a test discussion'
    fill_in 'comment_text', with: 'this is a reply'
    assert_difference -> { Comment.count } => 1 do
      click_button 'Create Comment'
      assert_content 'this is a reply'
    end
  end
end
