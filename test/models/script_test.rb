require 'test_helper'

class ScriptTest < ActiveSupport::TestCase
  test 'not enough discussions is not consecutive bad ratings' do
    script = Script.find(1)
    discussion = script.discussions.first
    discussion.update!(rating: Discussion::RATING_BAD, created_at: 1.week.ago)
    discussion.dup.save
    assert_not script.consecutive_bad_ratings?
  end

  test 'enough discussions is consecutive bad ratings' do
    script = Script.find(1)
    discussion = script.discussions.first
    discussion.update!(rating: Discussion::RATING_BAD, created_at: 1.week.ago)
    discussion.dup.update!(created_at: 1.week.ago)
    discussion.dup.update!(created_at: 1.week.ago)
    assert script.consecutive_bad_ratings?
  end

  test 'new bad discussions do not count' do
    script = Script.find(1)
    discussion = script.discussions.first
    discussion.update!(rating: Discussion::RATING_BAD, created_at: 1.week.ago)
    discussion.dup.update!(created_at: 1.week.ago)
    discussion.dup.update!(created_at: 1.hour.ago)
    assert_not script.consecutive_bad_ratings?
  end

  test 'new bad discussion is ignored but it counts if it has enough old bad discussions' do
    script = Script.find(1)
    discussion = script.discussions.first
    discussion.update!(rating: Discussion::RATING_BAD, created_at: 1.week.ago)
    discussion.dup.update!(created_at: 1.week.ago)
    discussion.dup.update!(created_at: 1.week.ago)
    discussion.dup.update!(created_at: 1.hour.ago)
    assert script.consecutive_bad_ratings?
  end

  test 'a non-bad rating resets' do
    script = Script.find(1)
    discussion = script.discussions.first
    discussion.update!(rating: Discussion::RATING_BAD, created_at: 1.week.ago)
    discussion.dup.update!(created_at: 1.week.ago)
    discussion.dup.update!(created_at: 1.week.ago)
    discussion.dup.update!(created_at: 1.week.ago, rating: Discussion::RATING_GOOD)
    discussion.dup.update!(created_at: 1.week.ago)
    assert_not script.consecutive_bad_ratings?
  end
end
