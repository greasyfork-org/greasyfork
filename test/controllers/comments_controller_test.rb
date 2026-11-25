require 'test_helper'

class CommentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActiveJob::TestHelper

  test 'legacy forum comment URL redirects using its discussion ID' do
    discussion = discussions(:non_script_discussion)
    discussion.update_column(:migrated_from, 123)
    legacy_comment = LegacyComment.create!(discussion_id: 123)

    get "/forum/discussion/comment/#{legacy_comment.id}"

    assert_response :moved_permanently
    assert_redirected_to discussion.path(locale: :en)
  end

  test 'editing an eligible discussion title queues a check even after later discussions' do
    comment = comments(:non_script_comment)
    discussion = comment.discussion
    comment.update!(created_at: Time.current)
    3.times { discussion.dup.save! }
    sign_in comment.poster
    get help_allowed_markup_path(locale: :en)
    token = response.parsed_body.at_css('meta[name="csrf-token"]')['content']

    assert_enqueued_with(job: CommentSpamCheckJob) do
      patch category_discussion_comment_path(category: 'greasyfork', category_discussion_id: discussion.id, id: comment.id, locale: :en),
            params: { authenticity_token: token, comment: { text: comment.text, text_markup: comment.text_markup, discussion: { title: 'Edited title' } } }
    end
    assert_response :redirect
    assert_equal 'Edited title', discussion.reload.title
  end

  test 'editing an eligible reply queues a check but later replies do not' do
    comment = comments(:non_script_comment_2)
    discussion = comment.discussion
    comment.update!(created_at: Time.current)
    later_comments = Array.new(3) { discussion.comments.create!(poster: comment.poster, text: 'another reply', text_markup: 'html') }
    sign_in comment.poster
    get help_allowed_markup_path(locale: :en)
    token = response.parsed_body.at_css('meta[name="csrf-token"]')['content']

    assert_enqueued_with(job: CommentSpamCheckJob) do
      patch category_discussion_comment_path(category: 'greasyfork', category_discussion_id: discussion.id, id: comment.id, locale: :en),
            params: { authenticity_token: token, comment: { text: 'edited reply', text_markup: 'markdown' } }
    end
    assert_response :redirect

    assert_no_enqueued_jobs(only: CommentSpamCheckJob) do
      patch category_discussion_comment_path(category: 'greasyfork', category_discussion_id: discussion.id, id: later_comments.last.id, locale: :en),
            params: { authenticity_token: token, comment: { text: 'later edited reply', text_markup: 'html' } }
    end
    assert_response :redirect
  end

  test 'saving an unchanged comment does not queue a check' do
    comment = comments(:non_script_comment_2)
    comment.update!(created_at: Time.current)
    sign_in comment.poster
    get help_allowed_markup_path(locale: :en)
    token = response.parsed_body.at_css('meta[name="csrf-token"]')['content']

    assert_no_enqueued_jobs(only: CommentSpamCheckJob) do
      patch category_discussion_comment_path(category: 'greasyfork', category_discussion_id: comment.discussion_id, id: comment.id, locale: :en),
            params: { authenticity_token: token, comment: { text: comment.text, text_markup: comment.text_markup } }
    end
    assert_response :redirect
  end
end
