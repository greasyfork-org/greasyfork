require 'test_helper'

class CommentsControllerTest < ActionDispatch::IntegrationTest
  test 'legacy forum comment URL redirects using its discussion ID' do
    discussion = discussions(:non_script_discussion)
    discussion.update_column(:migrated_from, 123)
    legacy_comment = LegacyComment.create!(discussion_id: 123)

    get "/forum/discussion/comment/#{legacy_comment.id}"

    assert_response :moved_permanently
    assert_redirected_to discussion.path(locale: :en)
  end
end
