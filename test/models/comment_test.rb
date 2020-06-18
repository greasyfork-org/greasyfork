require 'test_helper'

class CommentTest < ActiveSupport::TestCase
  test 'deleting the first comment deletes the whole discussion' do
    discussion = Discussion.create!(script: Script.first, rating: Discussion::RATING_GOOD, poster: User.first)
    comment_1 = discussion.comments.create!(text: 'blah', poster: User.first)
    comment_1.update_stats!
    comment_2 = discussion.comments.create!(text: 'blah', poster: User.first)
    comment_2.update_stats!
    comment_1.destroy
    assert discussion.destroyed?
    assert comment_1.destroyed?
    assert comment_2.destroyed?
  end
end
