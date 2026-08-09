require 'test_helper'

class UsersHelperTest < ActionView::TestCase
  test 'redacted email uses the last character of the local part' do
    assert_equal 'j…n@example.com', redacted_email('john@example.com')
  end
end
