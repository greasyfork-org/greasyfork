require 'test_helper'

class ReportsTest < ApplicationSystemTestCase
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
        click_on 'Create report'
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
          click_on 'Dismiss'
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
          click_on 'Mark as fixed'
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
          click_on 'Delete script'
          assert_content 'There are currently no actionable reports.'
        end
      end
    end

    assert_nil report.reload.moderator_reason_override
  end

  test 'moderator upholding a report for a script but for a different reason' do
    report = reports(:derivative_with_same_name_report)
    report.update!(reason: Report::REASON_MALWARE)
    moderator = users(:mod)
    login_as(moderator, scope: :user)
    visit reports_url(locale: :en)
    assert_content 'This is total spam!'
    assert_changes -> { report.reload.result }, from: nil, to: 'upheld' do
      assert_changes -> { report.item.reload.deleted? }, from: false, to: true do
        assert_enqueued_emails(2) do
          select 'Other'
          click_on 'Delete script'
          assert_content 'There are currently no actionable reports.'
        end
      end
    end

    report.reload
    assert_equal Report::REASON_MALWARE, report.reason
    assert_equal Report::REASON_OTHER, report.moderator_reason_override

    visit report_url(report, locale: :en)
    assert_content 'but they upheld it as Other'
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
          click_on 'Delete script'
          assert_content 'This script was deleted by you'
        end
      end
    end
    click_on 'this report'
    assert_content 'This is total spam!'
    click_on 'submit an appeal'
    assert_content 'If a moderator is satisfied by your updates'
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
        click_on 'Submit rebuttal'
        assert_content 'A moderator will review this report and your explanation and make a decision.'
        assert_content "#{user.name} said:\nNo it is not!"
      end
    end
  end

  test 'reporting blocked due to general bad reports' do
    user = users(:geoff)
    5.times { Report.create!(reporter: users(:junior), result: Report::RESULT_DISMISSED, item: users(:consumer), reason: Report::REASON_SPAM) }
    login_as(user, scope: :user)
    visit user_url(users(:consumer), locale: :en)
    click_on 'Report'
    assert_content 'Due to recent reports'
  end

  test 'reporting blocked due to already having reported the item' do
    user = users(:geoff)
    Report.create!(reporter: user, result: Report::RESULT_DISMISSED, item: users(:consumer), reason: Report::REASON_SPAM)
    login_as(user, scope: :user)
    visit user_url(users(:consumer), locale: :en)
    click_on 'Report'
    assert_content 'You have already'
  end

  test 'reporting blocked due to pending report of the same type' do
    user = users(:one)
    Report.create!(reporter: users(:junior), item: users(:consumer), reason: Report::REASON_SPAM)
    login_as(user, scope: :user)
    visit user_url(users(:consumer), locale: :en)
    click_on 'Report'
    choose 'Spam'
    click_button 'Create report'
    assert_content 'There is already a similar pending report on this item.'
  end
end
