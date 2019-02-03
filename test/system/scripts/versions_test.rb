require "application_system_test_case"

class VersionsTest < ApplicationSystemTestCase
  test "script show with version" do
    script = Script.find(1)
    visit script_url(script.id, version: script.script_versions.first.id, locale: :en)
    assert_selector 'h2', text: 'A Test!'
  end
end
