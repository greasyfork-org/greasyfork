require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'render user as json' do
    get user_url(users(:consumer), locale: :en, format: :json, host: 'api.greasyfork.local')
    assert_response :ok
  end

  test 'render users as json' do
    stub_es(User)
    get users_url(locale: :en, format: :json, host: 'api.greasyfork.local')
    assert_response :ok
  end

  test 'render users as jsonp' do
    stub_es(User)
    get users_url(locale: :en, format: :jsonp, host: 'api.greasyfork.local')
    assert_response :ok
  end

  test 'does not show forum options or confirmation summary to users without comments' do
    user = users(:junior)
    assert_not user.comments.exists?
    user.update_columns(delete_confirmation_key: 'confirmation-key', delete_confirmation_expiry: 1.day.from_now)
    sign_in user

    get user_delete_info_path(locale: :en)
    assert_response :ok
    assert_select '#forum-content-options', count: 0

    get user_delete_confirm_path(locale: :en, key: 'confirmation-key')
    assert_response :ok
    assert_not_includes response.body, I18n.t('users.delete.confirmation.forum_content_retain')
  end

  test 'shows forum options when the user has only soft-deleted comments' do
    user = users(:consumer)
    user.comments.update_all(deleted_at: Time.current)
    assert user.comments.exists?
    assert_not user.comments.not_deleted.exists?
    sign_in user

    get user_delete_info_path(locale: :en)
    assert_response :ok
    assert_select '#forum-content-options', count: 1
  end

  [false, true].each do |delete_forum_content|
    test "account deletion #{delete_forum_content ? 'deletes' : 'retains'} forum content" do
      user = users(:one)
      discussion = discussions(:non_script_discussion)
      first_comment = comments(:non_script_comment)
      other_users_reply = comments(:non_script_comment_2)
      soft_deleted_discussion = discussion.dup
      soft_deleted_discussion.save!
      soft_deleted_discussion.update_columns(deleted_at: Time.current)
      other_discussion = discussion.dup
      other_discussion.poster = users(:geoff)
      other_discussion.save!
      other_discussion.comments.create!(poster: users(:geoff), text: 'Original post', text_markup: 'html', first_comment: true)
      reply = other_discussion.comments.create!(poster: user, text: 'My reply', text_markup: 'html')
      reply.update_columns(deleted_at: Time.current)
      sign_in user

      get user_delete_info_path(locale: :en)
      assert_response :ok
      assert_select 'input[name=delete_forum_content][type=radio][value="0"][checked]'
      assert_select 'input[name=delete_forum_content][type=radio][value="1"]:not([checked])'
      assert_select 'form[action*="delete_start"] > p + input[type=submit]', 1
      token = response.parsed_body.at_css('meta[name="csrf-token"]')['content']

      start_params = { authenticity_token: token, delete_forum_content: delete_forum_content ? '1' : '0' }
      post user_delete_start_path(locale: :en), params: start_params
      assert_response :redirect
      user.reload
      assert_equal delete_forum_content, user.delete_confirmation_forum_content?

      get user_delete_confirm_path(locale: :en, key: user.delete_confirmation_key)
      assert_response :ok
      assert_select 'input[name=delete_forum_content]', count: 0
      assert_includes response.body, delete_forum_content ? 'will be permanently deleted' : 'chose to retain discussions you started'
      token = response.parsed_body.at_css('meta[name="csrf-token"]')['content']

      post user_delete_complete_path(locale: :en), params: {
        key: user.delete_confirmation_key,
        delete_forum_content: (delete_forum_content ? '0' : '1'),
        authenticity_token: token,
      }

      assert_response :redirect
      assert_not User.exists?(user.id)
      assert_equal !delete_forum_content, Discussion.exists?(discussion.id)
      assert_equal !delete_forum_content, Discussion.exists?(soft_deleted_discussion.id)
      assert_equal !delete_forum_content, Comment.exists?(first_comment.id)
      assert_equal !delete_forum_content, Comment.exists?(other_users_reply.id)
      assert_equal !delete_forum_content, Comment.exists?(reply.id)
      assert Discussion.exists?(other_discussion.id)
    end
  end

  test 'invalid confirmation does not delete forum content' do
    user = users(:one)
    discussion = discussions(:non_script_discussion)
    user.update_columns(delete_confirmation_key: 'confirmation-key', delete_confirmation_expiry: 1.day.from_now, delete_confirmation_forum_content: true)
    sign_in user
    get user_delete_confirm_path(locale: :en, key: 'confirmation-key')
    token = response.parsed_body.at_css('meta[name="csrf-token"]')['content']

    post user_delete_complete_path(locale: :en), params: {
      key: 'wrong-key', delete_forum_content: '1', authenticity_token: token
    }

    assert_response :redirect
    assert User.exists?(user.id)
    assert Discussion.exists?(discussion.id)
  end

  test 'a new deletion request replaces the previous choice and confirmation key' do
    user = users(:one)
    sign_in user
    get user_delete_info_path(locale: :en)
    token = response.parsed_body.at_css('meta[name="csrf-token"]')['content']

    post user_delete_start_path(locale: :en), params: { delete_forum_content: '1', authenticity_token: token }
    previous_key = user.reload.delete_confirmation_key
    assert user.delete_confirmation_forum_content?

    post user_delete_start_path(locale: :en), params: { authenticity_token: token }
    user.reload
    assert_not user.delete_confirmation_forum_content?
    assert_not_equal previous_key, user.delete_confirmation_key

    get user_delete_confirm_path(locale: :en, key: previous_key)
    assert_select 'form[action*="delete_complete"]', count: 0
    assert_includes response.body, 'keys do not match'
  end

  test 'cancelling account deletion does not delete forum content' do
    user = users(:one)
    discussion = discussions(:non_script_discussion)
    user.update_columns(delete_confirmation_key: 'confirmation-key', delete_confirmation_expiry: 1.day.from_now, delete_confirmation_forum_content: true)
    sign_in user
    get user_delete_confirm_path(locale: :en, key: 'confirmation-key')
    token = response.parsed_body.at_css('meta[name="csrf-token"]')['content']

    post user_delete_complete_path(locale: :en), params: {
      key: 'confirmation-key', delete_forum_content: '1', cancel: 'Cancel', authenticity_token: token
    }

    assert_response :redirect
    assert User.exists?(user.id)
    assert Discussion.exists?(discussion.id)
    assert_not user.reload.delete_confirmation_forum_content?
  end

  test 'account deletion failure rolls back forum deletion' do
    user = users(:one)
    discussion = discussions(:non_script_discussion)
    user.update_columns(delete_confirmation_key: 'confirmation-key', delete_confirmation_expiry: 1.day.from_now, delete_confirmation_forum_content: true)
    sign_in user
    get user_delete_confirm_path(locale: :en, key: 'confirmation-key')
    token = response.parsed_body.at_css('meta[name="csrf-token"]')['content']
    User.any_instance.expects(:destroy!).raises(ActiveRecord::RecordNotDestroyed)

    assert_raises(ActiveRecord::RecordNotDestroyed) do
      post user_delete_complete_path(locale: :en), params: {
        key: 'confirmation-key', delete_forum_content: '1', authenticity_token: token
      }
    end

    assert User.exists?(user.id)
    assert Discussion.exists?(discussion.id)
    assert Comment.exists?(comments(:non_script_comment).id)
  end
end
