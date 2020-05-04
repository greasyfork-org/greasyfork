require 'test_helper'

class ReportsTest < ApplicationSystemTestCase
  test 'reporting a user' do
    user = users(:one)
    login_as(user, scope: :user)
    visit user_url(users(:consumer), locale: :en)
    click_link 'Report'
    choose 'Spam'
    fill_in 'Provide additional details (optional)', with: 'and eggs'
    assert_difference -> { Report.count } => 1 do
      click_button 'Create report'
      assert_content 'Your report will be reviewed by a moderator.'
    end
    assert_equal users(:consumer), Report.last.item
  end

  test 'reporting a comment' do
    user = users(:one)
    login_as(user, scope: :user)
    comment = comments(:script_comment)
    visit comment.url
    click_link 'Report comment'
    choose 'Spam'
    fill_in 'Provide additional details (optional)', with: 'and eggs'
    assert_difference -> { Report.count } => 1 do
      click_button 'Create report'
      assert_content 'Your report will be reviewed by a moderator.'
    end
    assert_equal comment, Report.last.item
  end
end
