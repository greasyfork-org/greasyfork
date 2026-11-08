require 'test_helper'
require 'sidekiq-unique-jobs'
require 'stringio'

class ScriptStatsRefreshJobTest < ActiveSupport::TestCase
  test 'runs each step in order and starts the next run from fan counts' do
    output = StringIO.new
    ScriptStatsTiming.stubs(:logger).returns(Logger.new(output))
    order = sequence('refresh order')
    UpdateFanCounts.any_instance.expects(:perform).in_sequence(order)
    UpdateInstallCounts.any_instance.expects(:perform).in_sequence(order)
    UserStatsRefresh.any_instance.expects(:perform).in_sequence(order)

    ScriptStatsRefreshJob.new.perform

    assert_equal 'fan', ScriptStatsRefreshProgress.find(1).next_step
    assert_match(/ScriptStatsRefreshJob fan status=completed elapsed=\d+\.\d{3}s/, output.string)
    assert_match(/ScriptStatsRefreshJob install status=completed elapsed=\d+\.\d{3}s/, output.string)
    assert_match(/ScriptStatsRefreshJob user status=completed elapsed=\d+\.\d{3}s/, output.string)
  end

  test 'resumes from a failed step without repeating completed steps' do
    output = StringIO.new
    ScriptStatsTiming.stubs(:logger).returns(Logger.new(output))
    UpdateFanCounts.any_instance.expects(:perform).once
    UpdateInstallCounts.any_instance.expects(:perform).twice.raises('install failed').then.returns(nil)
    UserStatsRefresh.any_instance.expects(:perform).once

    assert_raises(RuntimeError) { ScriptStatsRefreshJob.new.perform }
    assert_equal 'install', ScriptStatsRefreshProgress.find(1).next_step
    assert_match(/ScriptStatsRefreshJob install status=failed elapsed=\d+\.\d{3}s/, output.string)
    ScriptStatsRefreshJob.new.perform
    assert_equal 'fan', ScriptStatsRefreshProgress.find(1).next_step
  end

  test 'resumes user refresh without repeating script updates' do
    UpdateFanCounts.any_instance.expects(:perform).once
    UpdateInstallCounts.any_instance.expects(:perform).once
    UserStatsRefresh.any_instance.expects(:perform).twice.raises('user failed').then.returns(nil)

    assert_raises(RuntimeError) { ScriptStatsRefreshJob.new.perform }
    assert_equal 'user', ScriptStatsRefreshProgress.find(1).next_step
    ScriptStatsRefreshJob.new.perform
    assert_equal 'fan', ScriptStatsRefreshProgress.find(1).next_step
  end

  test 'rejects invalid progress' do
    ScriptStatsRefreshProgress.create!(id: 1, next_step: 'invalid')
    assert_raises(RuntimeError) { ScriptStatsRefreshJob.new.perform }
  end

  test 'releases its unique lock after retries are exhausted' do
    digests = mock
    SidekiqUniqueJobs::Digests.expects(:new).returns(digests)
    digests.expects(:delete_by_digest).with('digest')

    ScriptStatsRefreshJob.sidekiq_retries_exhausted_block.call({ 'lock_digest' => 'digest' }, StandardError.new)
  end
end
