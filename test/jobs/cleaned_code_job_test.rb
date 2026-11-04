require 'test_helper'

class CleanedCodeJobTest < ActiveSupport::TestCase
  test 'it works' do
    script = scripts(:one)
    assert_empty CleanedCode.where(script_id: script.id)
    CleanedCodeJob.delete_for_script(script)
    CleanedCodeJob.perform_now(script)
    assert_not_empty CleanedCode.where(script_id: script.id)
  end
end
