require 'test_helper'

class ReportsTest < ApplicationSystemTestCase
  include ActionMailer::TestHelper

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

  test 'reporting a message' do
    user = users(:junior)
    conversation = conversations(:geoff_and_junior)
    login_as(user, scope: :user)
    visit user_conversation_url(user, conversation, locale: :en)
    click_link 'Report message'
    choose 'Spam'
    fill_in 'Provide additional details (optional)', with: 'and eggs'
    assert_difference -> { Report.count } => 1 do
      click_button 'Create report'
      assert_content 'Your report will be reviewed by a moderator.'
    end
    assert_equal conversation.messages.first, Report.last.item
  end

  test 'reporting a script' do
    user = users(:one)
    login_as(user, scope: :user)
    script = scripts(:two)
    visit script_url(script, locale: :en)
    click_link 'report the script'
    choose 'Spam'
    fill_in 'Provide additional details (optional)', with: 'and eggs'
    assert_difference -> { Report.count } => 1 do
      assert_enqueued_emails(1) do
        click_button 'Create report'
        assert_content 'Your report will be reviewed by a moderator.'
      end
    end
    assert_equal script, Report.last.item
  end

  test 'dismissing a report for a script' do
    report = reports(:derivative_with_same_name_report)
    moderator = users(:mod)
    login_as(moderator, scope: :user)
    visit reports_url(locale: :en)
    assert_content 'This is total spam!'
    assert_changes -> { report.reload.result }, from: nil, to: 'dismissed' do
      assert_no_changes -> { report.item.reload.deleted? } do
        assert_enqueued_emails(2) do
          click_button 'Dismiss'
          assert_content 'There are currently no actionable reports.'
        end
      end
    end
  end

  test 'marking a report as fixed for a script' do
    report = reports(:derivative_with_same_name_report)
    moderator = users(:mod)
    login_as(moderator, scope: :user)
    visit reports_url(locale: :en)
    assert_content 'This is total spam!'
    assert_changes -> { report.reload.result }, from: nil, to: 'fixed' do
      assert_no_changes -> { report.item.reload.deleted? } do
        assert_enqueued_emails(2) do
          click_button 'Mark as fixed'
          assert_content 'There are currently no actionable reports.'
        end
      end
    end
  end

  test 'moderator upholding a report for a script' do
    report = reports(:derivative_with_same_name_report)
    moderator = users(:mod)
    login_as(moderator, scope: :user)
    visit reports_url(locale: :en)
    assert_content 'This is total spam!'
    assert_changes -> { report.reload.result }, from: nil, to: 'upheld' do
      assert_changes -> { report.item.reload.deleted? }, from: false, to: true do
        assert_enqueued_emails(2) do
          click_button 'Delete script'
          assert_content 'There are currently no actionable reports.'
        end
      end
    end
  end

  test 'reported script author self-deleting' do
    report = reports(:derivative_with_same_name_report)
    user = report.item.users.first
    login_as(user, scope: :user)
    visit report_url(report, locale: :en)
    assert_content 'This is total spam!'
    assert_changes -> { report.reload.result }, from: nil, to: 'upheld' do
      assert_changes -> { report.item.reload.deleted? }, from: false, to: true do
        assert_enqueued_emails(1) do
          click_button 'Delete script'
          assert_content 'This script has been deleted and is not accessible'
        end
      end
    end
  end

  test 'reported script author submitting a rebuttal' do
    report = reports(:derivative_with_same_name_report)
    user = report.item.users.first
    login_as(user, scope: :user)
    visit report_url(report, locale: :en)
    assert_content 'This is total spam!'
    fill_in 'Explain to a moderator why this script should not be deleted.', with: 'No it is not!'
    assert_changes -> { report.reload.rebuttal } do
      assert_enqueued_emails(1) do
        click_button 'Submit rebuttal'
        assert_content 'A moderator will review this report and your explanation and make a decision.'
        assert_content "#{user.name} said:\nNo it is not!"
      end
    end
  end
end
