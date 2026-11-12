require 'test_helper'

class ElasticsearchCodeSearchJobTest < ActiveJob::TestCase
  test 'version creation and deletion enqueue indexing after commit' do
    script = scripts(:one)
    version = script.newest_saved_script_version.dup
    version.version = 'new'
    assert_enqueued_with(job: ElasticsearchCodeSearchJob, args: [script.id]) { version.save!(validate: false) }

    clear_enqueued_jobs
    assert_enqueued_with(job: ElasticsearchCodeSearchJob, args: [script.id]) { version.destroy! }
  end

  test 'version updates enqueue indexing after commit' do
    version = script_versions(:one)
    assert_enqueued_with(job: ElasticsearchCodeSearchJob, args: [version.script_id]) { version.update!(changelog: 'updated') }
  end

  test 'rolled back version creation does not enqueue indexing' do
    version = script_versions(:one).dup
    assert_no_enqueued_jobs(only: ElasticsearchCodeSearchJob) do
      ScriptVersion.transaction do
        version.save!(validate: false)
        raise ActiveRecord::Rollback
      end
    end
  end

  test 'job indexes using the script id' do
    ElasticsearchCodeSearch.expects(:index_script).with(123)
    ElasticsearchCodeSearchJob.perform_now(123)
  end
end
