require 'test_helper'

class ReportsFilingTest < ApplicationSystemTestCase
  include ActionMailer::TestHelper

  test 'reporting a user' do
    user = users(:one)
    login_as(user, scope: :user)
    visit user_url(users(:consumer), locale: :en)
    click_on 'Report'
    choose 'Spam'
    fill_in 'Provide additional details (optional)', with: 'and eggs'
    assert_difference -> { Report.count } => 1 do
      click_on 'Create report'
      assert_content 'Your report will be reviewed by a moderator.'
    end
    assert_equal users(:consumer), Report.last.item
  end

  test 'reporting a first comment' do
    user = users(:consumer)
    login_as(user, scope: :user)
    comment = comments(:non_script_comment)
    visit comment.url
    click_on 'Report comment'
    choose 'Spam'
    fill_in 'Provide additional details (optional)', with: 'and eggs'
    assert_difference -> { Report.count } => 1 do
      click_on 'Create report'
      assert_content 'Your report will be reviewed by a moderator.'
    end
    assert_equal comment.discussion, Report.last.item
  end

  test 'reporting a non-first comment' do
    user = users(:one)
    login_as(user, scope: :user)
    comment = comments(:non_script_comment_2)
    visit comment.url
    click_on 'Report comment'
    choose 'Spam'
    fill_in 'Provide additional details (optional)', with: 'and eggs'
    assert_difference -> { Report.count } => 1 do
      click_on 'Create report'
      assert_content 'Your report will be reviewed by a moderator.'
    end
    assert_equal comment, Report.last.item
  end

  test 'reporting a message' do
    user = users(:junior)
    conversation = conversations(:geoff_and_junior)
    login_as(user, scope: :user)
    visit user_conversation_url(user, conversation, locale: :en)
    click_on 'Report message'
    choose 'Spam'
    fill_in 'Provide additional details (optional)', with: 'and eggs'
    assert_difference -> { Report.count } => 1 do
      click_on 'Create report'
      assert_content 'Your report will be reviewed by a moderator.'
    end
    assert_equal conversation.messages.first, Report.last.item
  end

  test 'reporting a script' do
    user = users(:one)
    login_as(user, scope: :user)
    script = scripts(:two)
    visit script_url(script, locale: :en)
    click_on 'report the script'
    choose 'Spam'
    fill_in 'Provide additional details (optional)', with: 'and eggs'
    assert_difference -> { Report.count } => 1 do
      # 2 emails - one for each author
      assert_enqueued_emails(2) do
        assert_difference -> { Notification.count } => 2 do
          click_on 'Create report'
          assert_content 'Your report will be reviewed by a moderator.'
        end
      end
    end
    assert_equal script, Report.last.item
  end
end
