require 'application_system_test_case'

class StatsTest < ApplicationSystemTestCase
  test 'loads without error' do
    script = Script.find(2)
    visit stats_script_path(script, locale: :en)
  end
end
