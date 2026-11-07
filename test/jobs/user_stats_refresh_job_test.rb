require 'test_helper'
require 'active_support/testing/constant_stubbing'
require 'sidekiq-unique-jobs'

class UserStatsRefreshJobTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::ConstantStubbing

  test 'indexes authors in bounded batches with complete search data' do
    authors = User.where.associated(:authors).distinct.to_a
    expected = authors.index_with(&:search_data).transform_keys(&:id)
    requests = []
    client = Object.new
    client.define_singleton_method(:bulk) do |body:|
      requests << body
      { 'errors' => false }
    end
    Searchkick.stubs(:client).returns(client)
    job = UserStatsRefreshJob.new

    stub_const(UserStatsRefreshJob, :BATCH_SIZE, 2) { job.perform }

    assert_equal [2, 1], requests.map(&:size)
    indexed = requests.flatten.to_h { |entry| [entry[:index][:_id], entry[:index][:data]] }
    assert_equal expected, indexed
  end

  test 'indexing errors propagate for Sidekiq to retry' do
    client = Object.new
    client.define_singleton_method(:bulk) do |body:|
      { 'errors' => true, 'items' => [{ 'index' => { '_id' => body.first[:index][:_id], 'error' => { 'type' => 'rejected' } } }] }
    end
    Searchkick.stubs(:client).returns(client)
    job = UserStatsRefreshJob.new
    job.expects(:sleep).never

    assert_raises(Searchkick::ImportError) { job.perform }
  end

  test 'releases its unique lock after retries are exhausted' do
    digests = mock
    SidekiqUniqueJobs::Digests.expects(:new).returns(digests)
    digests.expects(:delete_by_digest).with('digest')

    UserStatsRefreshJob.sidekiq_retries_exhausted_block.call({ 'lock_digest' => 'digest' }, StandardError.new)
  end
end
