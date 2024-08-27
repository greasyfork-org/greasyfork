require 'application_system_test_case'

class StatsTest < ApplicationSystemTestCase
  test 'loads without error' do
    assert_no_error_reported do
      script = Script.find(2)
      visit stats_script_path(script, locale: :en)
    end
  end

  test 'CSV loads without error' do
    assert_no_error_reported do
      script = Script.find(2)
      visit stats_script_path(script, locale: :en, format: :csv)
    end
  end

  test 'JSON loads without error' do
    assert_no_error_reported do
      script = Script.find(2)
      visit stats_script_path(script, locale: :en, format: :json)
    end
  end
end
