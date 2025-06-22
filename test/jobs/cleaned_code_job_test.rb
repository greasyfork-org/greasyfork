require 'test_helper'

class CleanedCodeJobTest < ActiveSupport::TestCase
  test 'it works' do
    script = scripts(:one)
    assert_empty CleanedCode.where(script_id: script.id)
    CleanedCodeJob.delete_for_script(script)
    CleanedCodeJob.perform_now(script)
    assert_not_empty CleanedCode.where(script_id: script.id)
    assert_path_exists CleanedCodeJob.clean_path_for_script(script)
    assert_path_exists CleanedCodeJob.dirty_path_for_script(script)
  end
end
