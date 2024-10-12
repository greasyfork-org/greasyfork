require 'test_helper'

class ConsecutiveBadRatingsJobTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test 'date is cleared if it no longer applies' do
    script = Script.first
    script.update(consecutive_bad_ratings_at: Time.current)
    ConsecutiveBadRatingsJob.perform_inline
    assert_nil script.reload.consecutive_bad_ratings_at
  end

  test 'date is added if it applies' do
    script = Script.first
    Script.any_instance.expects(:consecutive_bad_ratings?).returns(true)
    ConsecutiveBadRatingsJob.any_instance.expects(:scripts_with_discussions).returns([script.id])
    assert_difference -> { Notification.count } => 1 do
      ConsecutiveBadRatingsJob.perform_inline
    end
    assert_enqueued_email_with ConsecutiveBadRatingsMailer, :notify, args: [script, script.users.first, :en]
    assert_not_nil script.reload.consecutive_bad_ratings_at
  end

  test 'script is not deleted prior to the grace period' do
    script = Script.first
    script.update(consecutive_bad_ratings_at: 1.week.ago)
    Script.any_instance.expects(:consecutive_bad_ratings?).returns(true)
    ConsecutiveBadRatingsJob.perform_inline
    assert_not script.reload.deleted?
  end

  test 'script is deleted past the grace period' do
    script = Script.first
    script.update(consecutive_bad_ratings_at: 2.weeks.ago - 1.second)
    Script.any_instance.expects(:consecutive_bad_ratings?).returns(true)
    ConsecutiveBadRatingsJob.perform_inline
    assert script.reload.deleted?
  end
end
