require 'test_helper'

class ScriptLockAppealsTest < ApplicationSystemTestCase
  include ActionMailer::TestHelper

  test 'appealing a script delete' do
    user = users(:one)
    login_as(user, scope: :user)
    script = scripts(:two)
    script.update!(locked: true, delete_type: 'redirect')
    report = script.reports.create!(reason: Report::REASON_ABUSE, result: 'upheld', reporter: users(:geoff))
    visit script_url(script, locale: :en)
    click_on 'submit an appeal'
    fill_in 'Appeal', with: "No it's good"
    click_on 'Submit appeal'
    assert_content 'Your appeal has been received and a moderator will review it.'
    assert_equal report, ScriptLockAppeal.last.report
  end

  test "appealing a script delete, but there's already an open appeal" do
    user = users(:one)
    login_as(user, scope: :user)
    script = scripts(:two)
    script.update!(locked: true, delete_type: 'redirect')
    report = script.reports.create!(reason: Report::REASON_ABUSE, result: 'upheld', reporter: users(:geoff))
    ScriptLockAppeal.create!(script:, report:, resolution: :unresolved, text: 'whatever')
    visit script_url(script, locale: :en)
    click_on 'submit an appeal'
    assert_content 'There is already an open appeal'
  end

  test 'appealing a script delete, and there is already a dismissed appeal' do
    user = users(:one)
    login_as(user, scope: :user)
    script = scripts(:two)
    script.update!(locked: true, delete_type: 'redirect')
    report = script.reports.create!(reason: Report::REASON_ABUSE, result: 'upheld', reporter: users(:geoff))
    ScriptLockAppeal.create!(script:, report:, resolution: :dismissed, text: 'whatever')
    visit script_url(script, locale: :en)
    click_on 'submit an appeal'
    fill_in 'Appeal', with: "No it's good"
    click_on 'Submit appeal'
    assert_content 'Your appeal has been received and a moderator will review it.'
  end
end
