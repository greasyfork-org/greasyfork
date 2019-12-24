require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def around(&block)
    with_sphinx do
      block.call
    end
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
end
