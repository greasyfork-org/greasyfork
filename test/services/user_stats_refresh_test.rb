require 'test_helper'
require 'active_support/testing/constant_stubbing'

class UserStatsRefreshTest < ActiveSupport::TestCase
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
    refresh = UserStatsRefresh.new

    stub_const(UserStatsRefresh, :BATCH_SIZE, 2) { refresh.perform }

    assert_equal [2, 1], requests.map(&:size)
    indexed = requests.flatten.to_h { |entry| [entry[:index][:_id], entry[:index][:data]] }
    assert_equal expected, indexed
  end

  test 'indexing errors propagate to the caller' do
    client = Object.new
    client.define_singleton_method(:bulk) do |body:|
      { 'errors' => true, 'items' => [{ 'index' => { '_id' => body.first[:index][:_id], 'error' => { 'type' => 'rejected' } } }] }
    end
    Searchkick.stubs(:client).returns(client)
    refresh = UserStatsRefresh.new
    refresh.expects(:sleep).never

    assert_raises(Searchkick::ImportError) { refresh.perform }
  end
end
