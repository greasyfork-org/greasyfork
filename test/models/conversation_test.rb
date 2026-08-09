require 'test_helper'

class ConversationTest < ActiveSupport::TestCase
  test 'latest url stays on the first page with exactly 50 messages' do
    conversation = conversations(:geoff_and_junior)
    messages = conversation.messages
    messages.stubs(:count).returns(50)
    conversation.stubs(:messages).returns(messages)

    assert_not_includes conversation.latest_url(users(:geoff), locale: 'en'), 'page='
  end

  test 'latest url uses the second page with 51 messages' do
    conversation = conversations(:geoff_and_junior)
    messages = conversation.messages
    messages.stubs(:count).returns(51)
    conversation.stubs(:messages).returns(messages)

    assert_includes conversation.latest_url(users(:geoff), locale: 'en'), 'page=2'
  end
end
