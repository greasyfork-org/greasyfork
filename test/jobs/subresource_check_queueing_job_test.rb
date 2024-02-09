require 'test_helper'

class SubresourceCheckQueueingJobTest < ActiveSupport::TestCase
  test 'it runs' do
    subresource = Subresource.create!(url: 'https://cdn.jsdelivr.net/npm/jquery@3.2.1/dist/jquery.min.js')
    subresource.script_subresource_usages.create!(script: Script.first, algorithm: 'md5', integrity_hash: 'abc123')

    assert_changes -> { subresource.reload.last_attempt_at } do
      SubresourceCheckQueueingJob.perform_inline
    end
  end
end
