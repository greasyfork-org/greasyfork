require 'test_helper'

class DiscussionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActiveJob::TestHelper

  test 'does not queue a check for a new user rating after three discussions' do
    user = users(:consumer)
    user.update!(created_at: 1.day.ago)
    3.times do
      discussion = discussions(:script_discussion).dup
      discussion.poster = user
      discussion.save!
    end
    sign_in user
    get help_allowed_markup_path(locale: :en)
    token = response.parsed_body.at_css('meta[name="csrf-token"]')['content']

    assert_no_enqueued_jobs(only: CommentSpamCheckJob) do
      post script_discussions_path(script_id: scripts(:one), locale: :en), params: {
        authenticity_token: token,
        discussion: { rating: Discussion::RATING_BAD, comments_attributes: { '0' => { text: 'a review', text_markup: 'html' } } },
      }
    end
    assert_response :redirect
  end
end
