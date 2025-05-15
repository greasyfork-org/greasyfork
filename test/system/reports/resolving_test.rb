require 'test_helper'

class ReportsResolvingTest < ApplicationSystemTestCase
  include ActionMailer::TestHelper

  test 'dismissing a report for a script' do
    report = reports(:derivative_with_same_name_report)
    moderator = users(:mod)
    login_as(moderator, scope: :user)
    visit reports_url(locale: :en)
    assert_content 'This is total spam!'
    assert_changes -> { report.reload.result }, from: nil, to: 'dismissed' do
      assert_no_changes -> { report.item.reload.deleted? } do
        assert_enqueued_emails(2) do
          assert_difference -> { Notification.count } => 2 do
            click_on 'Dismiss'
            assert_content 'There are currently no actionable reports.'
          end
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
          assert_difference -> { Notification.count } => 2 do
            click_on 'Mark as fixed'
            assert_content 'There are currently no actionable reports.'
          end
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
          assert_difference -> { Notification.count } => 2 do
            click_on 'Delete script'
            assert_content 'There are currently no actionable reports.'
          end
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
          assert_difference -> { Notification.count } => 2 do
            select 'Other'
            click_on 'Delete script'
            assert_content 'There are currently no actionable reports.'
          end
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
          assert_difference -> { Notification.count } => 1 do
            click_on 'Delete script'
            assert_content 'This script was deleted by you'
          end
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
        assert_difference -> { Notification.count } => 1 do
          click_on 'Submit rebuttal'
          assert_content 'A moderator will review this report and your explanation and make a decision.'
          assert_content "#{user.name}AUTHOR said:\nNo it is not!"
        end
      end
    end
  end
end
