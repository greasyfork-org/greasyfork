require 'test_helper'

class ScriptLockAppealsTest < ApplicationSystemTestCase
  include ActionMailer::TestHelper

  test 'reporting a script' do
    user = users(:one)
    login_as(user, scope: :user)
    script = scripts(:two)
    script.update!(locked: true, delete_type: 'redirect')
    visit script_url(script, locale: :en)
    click_link 'submit an appeal'
    fill_in 'Appeal', with: "No it's good"
    click_button 'Submit appeal'
    assert_content 'Your appeal has been received and a moderator will review it.'
  end
end
