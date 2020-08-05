require 'test_helper'

class MarkAsReadTest < ApplicationSystemTestCase
  test 'marking all discussions read' do
    user = User.first
    login_as(user, scope: :user)
    visit discussions_path(locale: :en)
    assert_selector '.discussion-not-read'
    click_link 'Mark all read'
    assert_no_selector '.discussion-not-read'
  end

  test 'marking some discussions read' do
    user = User.first
    login_as(user, scope: :user)
    visit discussions_path(locale: :en, category: 'greasyfork')
    assert_selector '.discussion-not-read'
    click_link 'Mark all read'
    assert_no_selector '.discussion-not-read'
    visit discussions_path(locale: :en)
    assert_selector '.discussion-not-read'
  end
end
