require 'test_helper'

class ScriptDuplicateCheckerJobTest < ActiveSupport::TestCase
  test 'no exceptions' do
    assert_no_error_reported do
      ScriptDuplicateCheckerJob.perform_inline(scripts(:one).id)
    end
  end
end
