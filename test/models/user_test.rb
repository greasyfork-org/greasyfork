require 'test_helper'

class UserTest < ActiveSupport::TestCase
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

  test 'invisible characters are OK if they do not match an existing user' do
    new_user = User.new(name: "i like weird\u2064chars", email: 'test@aol.com', password: 'password')
    assert new_user.valid?, new_user.errors.messages
  end

  test 'invisible characters are not OK if they match an existing user' do
    existing_user = users(:one)
    new_user = User.new(name: 'foo', email: 'test@aol.com', password: 'password')
    assert new_user.valid?, new_user.errors.messages
    new_user.name = existing_user.name
    new_user.name.insert(2, "\u2064")
    assert_not new_user.valid?
  end

  test 'reserved unicode characters are not OK' do
    new_user = User.new(name: "i like weird\ufff7chars", email: 'test@myexample.com', password: 'password')
    assert_not new_user.valid?, new_user.errors.messages
  end
end
