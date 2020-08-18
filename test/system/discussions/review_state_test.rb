require 'test_helper'

class ReviewStateTest < ApplicationSystemTestCase
  test "with review_reason doesn't show in index" do
    discussion = discussions(:non_script_discussion)
    discussion.update!(review_reason: 'akismet')

    visit discussions_path
    assert_no_content discussion.title
  end

  test 'without review_reason does show in index' do
    discussion = discussions(:non_script_discussion)
    discussion.update!(review_reason: nil)

    visit discussions_path
    assert_content discussion.title
  end

  test "with review_reason doesn't show directly" do
    discussion = discussions(:non_script_discussion)
    discussion.update!(review_reason: 'akismet')

    allow_js_error 'the server responded with a status of 404' do
      visit category_discussion_path(discussion, category: discussion.discussion_category.category_key, locale: :en)
      assert_no_content discussion.title
    end
  end

  test 'with review_reason does show directly for the OP' do
    discussion = discussions(:non_script_discussion)
    discussion.update!(review_reason: 'akismet')

    login_as(discussion.poster, scope: :user)

    visit category_discussion_path(discussion, category: discussion.discussion_category.category_key, locale: :en)
    assert_content discussion.title
    assert_content 'This discussion is unavailable to other users until it is reviewed by a moderator.'
  end

  test 'without review_reason does show directly' do
    discussion = discussions(:non_script_discussion)
    discussion.update!(review_reason: nil)

    visit category_discussion_path(discussion, category: discussion.discussion_category.category_key, locale: :en)
    assert_content discussion.title
  end
end
