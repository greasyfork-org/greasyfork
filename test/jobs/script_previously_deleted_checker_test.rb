require 'test_helper'

class ScriptPreviouslyDeletedCheckerTest < ActiveSupport::TestCase
  include Rails.application.routes.url_helpers

  test 'when there are no similar scripts, does nothing' do
    script = Script.first
    assert_no_difference -> { Report.count } do
      ScriptPreviouslyDeletedChecker.perform_now(script.id)
    end
  end

  test 'when there are similar scripts, but not locked, does nothing' do
    script = Script.first
    script_2 = Script.second
    script_3 = Script.third
    ScriptSimilarity.delete_all
    ScriptSimilarity.create!(script:, other_script: script_2, similarity: 0.9, checked_at: Time.zone.now)
    ScriptSimilarity.create!(script:, other_script: script_3, similarity: 0.9, checked_at: Time.zone.now)
    assert_no_difference -> { Report.count } do
      ScriptPreviouslyDeletedChecker.perform_now(script.id)
    end
  end

  test 'when there are similar locked scripts' do
    script = Script.first
    script_2 = Script.second
    script_3 = Script.third
    ScriptSimilarity.delete_all
    ScriptSimilarity.create!(script:, other_script: script_2, similarity: 0.9, checked_at: Time.zone.now)
    ScriptSimilarity.create!(script:, other_script: script_3, similarity: 0.9, checked_at: Time.zone.now)
    initial_report = Report.create!(item: script_2, result: Report::RESULT_UPHELD, reason: Report::REASON_MALWARE, reporter: User.first, explanation: 'virus')
    script_2.update!(locked: true)
    script_3.update!(locked: true)
    assert_difference -> { Report.count } => 1 do
      ScriptPreviouslyDeletedChecker.perform_now(script.id)
    end
    new_report = Report.last
    assert_equal Report::REASON_MALWARE, new_report.reason
    assert_includes new_report.explanation, script_url(script_2, locale: nil)
    assert_includes new_report.explanation, script_url(script_3, locale: nil)
    assert_includes new_report.explanation, report_url(initial_report, locale: nil)
  end

  test 'when there are similar locked scripts, but they were auto-reported' do
    script = Script.first
    script_2 = Script.second
    script_3 = Script.third
    ScriptSimilarity.delete_all
    ScriptSimilarity.create!(script:, other_script: script_2, similarity: 0.9, checked_at: Time.zone.now)
    ScriptSimilarity.create!(script:, other_script: script_3, similarity: 0.9, checked_at: Time.zone.now)
    Report.create!(item: script_2, result: Report::RESULT_UPHELD, reason: Report::REASON_MALWARE, auto_reporter: 'hardy', explanation: 'virus')
    script_2.update!(locked: true)
    script_3.update!(locked: true)
    assert_no_difference -> { Report.count } do
      ScriptPreviouslyDeletedChecker.perform_now(script.id)
    end
  end

  test 'when there are similar locked scripts, but they were for no description' do
    script = Script.first
    script_2 = Script.second
    script_3 = Script.third
    ScriptSimilarity.delete_all
    ScriptSimilarity.create!(script:, other_script: script_2, similarity: 0.9, checked_at: Time.zone.now)
    ScriptSimilarity.create!(script:, other_script: script_3, similarity: 0.9, checked_at: Time.zone.now)
    Report.create!(item: script_2, result: Report::RESULT_UPHELD, reason: Report::REASON_NO_DESCRIPTION, reporter: User.first)
    script_2.update!(locked: true)
    script_3.update!(locked: true)
    assert_no_difference -> { Report.count } do
      ScriptPreviouslyDeletedChecker.perform_now(script.id)
    end
  end

  test 'for unauthorized copy' do
    script = Script.first
    script_2 = Script.second
    script_3 = Script.third
    reference_script = scripts(:derivative_with_same_name)

    ScriptSimilarity.delete_all
    ScriptSimilarity.create!(script:, other_script: script_2, similarity: 0.9, checked_at: Time.zone.now)
    ScriptSimilarity.create!(script:, other_script: script_3, similarity: 0.9, checked_at: Time.zone.now)

    Report.create!(item: script_2, result: Report::RESULT_UPHELD, reason: Report::REASON_UNAUTHORIZED_CODE, reporter: User.first, reference_script:)
    script_2.update!(locked: true)
    script_3.update!(locked: true)
    assert_difference -> { Report.count } => 1 do
      ScriptPreviouslyDeletedChecker.perform_now(script.id)
    end
    assert_equal reference_script, Report.last.reference_script
  end

  test 'previous was deleted for unauthorized copy, but original author is the same as this one' do
    script = Script.first
    script_2 = Script.second
    script_3 = Script.third
    original_script = scripts(:derivative_with_same_name)
    script.authors.create!(user: original_script.users.first)

    ScriptSimilarity.delete_all
    ScriptSimilarity.create!(script:, other_script: script_2, similarity: 0.9, checked_at: Time.zone.now)
    ScriptSimilarity.create!(script:, other_script: script_3, similarity: 0.9, checked_at: Time.zone.now)

    Report.create!(item: script_2, result: Report::RESULT_UPHELD, reason: Report::REASON_UNAUTHORIZED_CODE, reporter: User.first, reference_script: original_script)
    script_2.update!(locked: true)
    script_3.update!(locked: true)
    assert_no_difference -> { Report.count } do
      ScriptPreviouslyDeletedChecker.perform_now(script.id)
    end
  end
end
