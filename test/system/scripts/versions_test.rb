require 'application_system_test_case'

class VersionsTest < ApplicationSystemTestCase
  test 'script show with version' do
    script = Script.find(1)
    visit script_url(script.id, version: script.script_versions.first.id, locale: :en)
    assert_selector 'h2', text: 'A Test!'
  end

  test 'deleted script versions' do
    script = Script.find(2)
    script.update!(delete_type: 'keep')
    script.script_applies_tos.create!(site_application: site_applications(:example_com_application))
    assert_script_deleted_page do
      visit script_script_versions_path(script_id: script, locale: :en)
    end
  end

  test 'deleted replaced script with versions' do
    script = Script.find(2)
    replacing_script = Script.find(1)
    script.update!(delete_type: 'redirect', replaced_by_script: replacing_script)
    visit script_script_versions_path(script_id: script, locale: :en)
    assert_current_path script_script_versions_path(script_id: replacing_script, locale: :en)
  end

  test 'script versions json' do
    assert_no_error_reported do
      script = Script.find(2)
      visit script_script_versions_path(script_id: script, locale: :en, format: :json)
    end
  end
end
