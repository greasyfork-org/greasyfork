require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def around(&)
    with_sphinx(&)
  end

  test 'deleting scripts where they are the sole author' do
    user = User.find(1)
    assert_equal user, Script.find(1).users.first
    user.destroy!
    assert_nil Script.find_by(id: 1)
  end

  test 'not deleting scripts where they are not the sole author' do
    user = User.find(1)
    assert_equal user, Script.find(2).users.first
    user.destroy!
    assert_not_nil Script.find_by(id: 2)
  end

  test 'deleting a banned user' do
    user = User.find(1)
    user.update!(banned_at: Time.current)
    assert_difference -> { BannedEmailHash.count } => 1 do
      assert_changes -> { User.email_previously_banned_and_deleted?(user.email) }, from: false, to: true do
        user.destroy!
      end
    end
  end

  test 'blocked_from_reporting_until with no reports' do
    user = users(:one)
    assert_nil user.blocked_from_reporting_until
  end

  test 'blocked_from_reporting_until with reports' do
    user = users(:one)
    4.times { Report.create!(reporter: user, result: Report::RESULT_DISMISSED, item: Script.first, reason: Report::REASON_SPAM) }
    assert_nil user.blocked_from_reporting_until
    Report.create!(reporter: user, result: Report::RESULT_DISMISSED, item: Script.first, reason: Report::REASON_SPAM)
    assert_not_nil user.blocked_from_reporting_until
    Report.last.update!(result: Report::RESULT_UPHELD)
    assert_nil user.blocked_from_reporting_until
  end
end
