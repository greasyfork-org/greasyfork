require 'test_helper'

class CommentTest < ActiveSupport::TestCase
  test 'deleting the first comment deletes the whole discussion' do
    comment1 = comments(:non_script_comment)
    comment2 = comments(:non_script_comment_2)
    discussion = comment1.discussion
    comment1.destroy!
    assert Discussion.where(id: discussion.id).none?
    assert Comment.where(id: [comment1.id, comment2.id]).none?
  end

  test 'deleting the second comment does not delete the whole discussion' do
    comment1 = comments(:non_script_comment)
    comment2 = comments(:non_script_comment_2)
    discussion = comment1.discussion
    comment2.destroy!
    assert Discussion.where(id: discussion.id).any?
    assert Comment.where(id: comment1.id).any?
    assert Comment.where(id: comment2.id).none?
  end

  test 'soft-deleting the first comment soft-deletes the whole discussion' do
    comment1 = comments(:non_script_comment)
    comment2 = comments(:non_script_comment_2)
    discussion = comment1.discussion
    comment1.soft_destroy!
    assert discussion.reload.soft_deleted?
    assert comment1.reload.soft_deleted?
    assert comment2.reload.soft_deleted?
  end

  test 'soft-deleting the second comment does not soft-deletes the whole discussion' do
    comment1 = comments(:non_script_comment)
    comment2 = comments(:non_script_comment_2)
    discussion = comment1.discussion
    comment2.soft_destroy!
    assert_not discussion.reload.soft_deleted?
    assert_not comment1.reload.soft_deleted?
    assert comment2.reload.soft_deleted?
  end
end
