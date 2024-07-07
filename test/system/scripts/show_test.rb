require 'application_system_test_case'

class ShowTest < ApplicationSystemTestCase
  test 'all authors can see author links' do
    script = Script.find(2)
    assert_operator script.users.count, :>, 1
    script.users.each do |user|
      login_as(user, scope: :user)
      visit script_path(script, locale: :en)
      click_on 'Update'
    end
  end

  test 'all authors should be listed' do
    script = Script.find(2)
    visit script_path(script, locale: :en)
    script.users.each do |user|
      assert_selector 'a', text: user.name
    end
  end

  test 'deleted script not replaced' do
    script = Script.find(2)
    script.update!(delete_type: 'keep')
    assert_script_deleted_page do
      visit script_path(script, locale: :en)
    end
  end

  test 'deleted script replaced' do
    script = Script.find(2)
    replacing_script = Script.find(1)
    script.update!(delete_type: 'redirect', replaced_by_script: replacing_script)
    visit script_path(script, locale: :en)
    assert_current_path script_path(replacing_script, locale: :en)
  end

  test 'license text format shows properly' do
    script = Script.find(2)
    script.update!(license_text: 'Example License; https://example.com')
    visit script_path(script, locale: :en)
    assert_link('Example License', href: 'https://example.com')
  end

  test 'applies to is rendered' do
    script = Script.find(25)
    with_sphinx do
      visit script_path(script, locale: :en)
      assert_content('example.com')
    end
  end

  test 'applies to is rendered as a link' do
    script = Script.find(25)
    other_script = Script.find(2)
    other_script.script_applies_tos.create!(site_application: script.site_applications.first)
    TopSitesService.refresh!
    with_sphinx do
      visit script_path(script, locale: :en)
      assert_link('example.com')
    end
  end
end
