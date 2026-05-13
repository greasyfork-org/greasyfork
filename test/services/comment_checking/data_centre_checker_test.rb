require 'test_helper'

class DataCentreCheckerTest < ActiveSupport::TestCase
  test "when it's not a data centre" do
    comment = comments(:script_comment)

    DataCentreIps.any_instance.expects(:data_centre?).returns(false)

    checker = CommentChecking::DataCentreChecker.new(comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot')

    assert_not checker.skip?
    assert_not CommentChecking::DataCentreChecker.new(comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot').check.spam?
  end

  test 'when it is a data centre' do
    comment = comments(:script_comment)

    DataCentreIps.any_instance.expects(:data_centre?).returns(true)

    checker = CommentChecking::DataCentreChecker.new(comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot')
    assert_not checker.skip?
    assert checker.check.spam?
  end

  test "when it is a data centre but not the user's first comment" do
    comment = comments(:script_comment).dup
    comment.save!

    assert CommentChecking::DataCentreChecker.new(comment, ip: '127.0.0.1', referrer: nil, user_agent: 'Bot').skip?
  end
end
