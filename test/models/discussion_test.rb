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

  test 'discussion is deletable by user who posted it immediately after posting' do
    discussion = discussions(:script_discussion)
    assert discussion.deletable_by?(discussion.poster)
  end

  test 'discussion is not deletable by user who posted it long after posting' do
    travel_to 1.hour.from_now do
      discussion = discussions(:script_discussion)
      assert_not discussion.deletable_by?(discussion.poster)
    end
  end

  test 'discussion is not deletable if there are replies by another user' do
    discussion = discussions(:non_script_discussion)
    assert_not discussion.deletable_by?(discussion.poster)
  end
end
