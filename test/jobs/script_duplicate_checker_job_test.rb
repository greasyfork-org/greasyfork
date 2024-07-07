require 'test_helper'

class ScriptDuplicateCheckerJobTest < ActiveSupport::TestCase
  test 'no exceptions' do
    ScriptDuplicateCheckerJob.perform_inline(scripts(:one).id)
  end
end
