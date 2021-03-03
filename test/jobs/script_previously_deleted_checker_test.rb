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
    ScriptSimilarity.create!(script: script, other_script: script_2, similarity: 0.9, checked_at: Time.zone.now)
    ScriptSimilarity.create!(script: script, other_script: script_3, similarity: 0.9, checked_at: Time.zone.now)
    assert_no_difference -> { Report.count } do
      ScriptPreviouslyDeletedChecker.perform_now(script.id)
    end
  end

  test 'when there are similar locked scripts' do
    script = Script.first
    script_2 = Script.second
    script_3 = Script.third
    ScriptSimilarity.create!(script: script, other_script: script_2, similarity: 0.9, checked_at: Time.zone.now)
    ScriptSimilarity.create!(script: script, other_script: script_3, similarity: 0.9, checked_at: Time.zone.now)
    initial_report = Report.create!(item: script_2, result: Report::RESULT_UPHELD, reason: Report::REASON_MALWARE, reporter: User.first)
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
end
