require 'test_helper'

class DiscussionTest < ActiveSupport::TestCase
  test 'deleting discussion deletes the comments' do
    discussion = discussions(:non_script_discussion)
    assert_difference -> { Discussion.count } => -1, -> { Comment.count } => -2 do
      discussion.destroy
    end
  end

  test 'soft-deleting discussion deletes the comments' do
    discussion = discussions(:non_script_discussion)
    assert_equal 2, discussion.comments.count
    discussion.soft_destroy!
    assert discussion.soft_deleted?
    assert_equal 2, discussion.comments.count
    assert discussion.comments.all?(&:soft_deleted?)
  end
end
