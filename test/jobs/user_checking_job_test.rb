require 'test_helper'

class UserCheckingJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test 'it bans on match' do
    user = users(:one)
    BlockedUser.create!(pattern: 'Timmy')

    assert_changes -> { user.reload.banned? } do
      UserCheckingJob.perform_now(user)
    end
  end

  test 'it does not ban on no match' do
    user = users(:one)
    BlockedUser.create!(pattern: 'Tommy')

    assert_no_changes -> { user.reload.banned? } do
      UserCheckingJob.perform_now(user)
    end
  end

  test 'repeating detects three repeated groups' do
    assert UserCheckingJob.new.repeating?('abcabcabc')
  end

  test 'repeating rejects a different third group' do
    assert_not UserCheckingJob.new.repeating?('abcabcdef')
  end
end
