require 'test_helper'

class CommentTest < ActiveSupport::TestCase
  test 'deleting the first comment deletes the whole discussion' do
    discussion = Discussion.create!(script: Script.first, rating: Discussion::RATING_GOOD, poster: User.first)
    comment1 = discussion.comments.create!(text: 'blah', poster: User.first)
    comment1.update_stats!
    comment2 = discussion.comments.create!(text: 'blah', poster: User.first)
    comment2.update_stats!
    comment1.destroy
    assert discussion.destroyed?
    assert comment1.destroyed?
    assert comment2.destroyed?
  end
end
