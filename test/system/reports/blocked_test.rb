require 'test_helper'

class ReportsBlockedTest < ApplicationSystemTestCase
  include ActionMailer::TestHelper

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
