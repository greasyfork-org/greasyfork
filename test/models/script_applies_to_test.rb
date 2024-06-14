require 'test_helper'

class ScriptAppliesToTest < ActiveSupport::TestCase
  test 'deleting also deletes SiteApplication if not otherwise used' do
    script = scripts(:example_com_application)
    assert_equal 1, script.script_applies_tos.count
    assert_equal 1, SiteApplication.where(text: 'example.com').count
    assert_difference -> { SiteApplication.where(text: 'example.com').count }, -1 do
      assert_difference -> { ScriptAppliesTo.count }, -1 do
        with_sphinx do
          script.destroy!
        end
      end
    end
  end

  test "deleting retains SiteApplication if it's used elsewhere" do
    script = scripts(:example_com_application)

    with_sphinx do
      other_script = scripts(:one)
      other_script.script_applies_tos.create!(site_application: SiteApplication.find_by(text: 'example.com'))

      assert_no_difference -> { SiteApplication.where(text: 'example.com').count } do
        assert_difference -> { ScriptAppliesTo.count }, -1 do
          script.destroy!
        end
      end
    end
  end
end
