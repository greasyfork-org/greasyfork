require 'test_helper'

class UnsubscribeControllerTest < ActionDispatch::IntegrationTest
  test 'valid unsubscribe' do
    user = users(:one)
    user.update!(subscribe_on_discussion: true)
    post one_click_unsubscribe_url(token: user.generate_token_for(:one_click_unsubscribe))
    assert_response :ok
    refute user.reload.subscribe_on_discussion
  end

  test 'bad token' do
    post one_click_unsubscribe_url(token: 'invalidtoken')
    assert_response :ok
  end
end
