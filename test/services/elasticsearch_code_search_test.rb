require 'test_helper'

class ElasticsearchCodeSearchTest < ActiveSupport::TestCase
  test 'search escapes wildcard characters and retrieves every page' do
    Rails.logger.expects(:info).with(regexp_matches(/\AElasticsearch code search status=completed elapsed=\d+\.\d{3}s\z/)).once
    client = mock
    Searchkick.stubs(:client).returns(client)
    client.expects(:search).with do |arguments|
      assert_equal ElasticsearchCodeSearch.index_name, arguments[:index]
      assert_equal '*a\\*b\\?c\\\\d*', arguments.dig(:body, :query, :bool, :filter, 0, :wildcard, :code, :value)
      assert_equal [2, 3], arguments.dig(:body, :query, :bool, :filter, 1, :ids, :values)
      true
    end.returns({ '_scroll_id' => 'first', 'hits' => { 'hits' => [{ '_id' => '2' }] }, '_shards' => { 'failed' => 0 } })
    client.expects(:scroll).with(scroll_id: 'first', scroll: '2m').returns(
      { '_scroll_id' => 'second', 'hits' => { 'hits' => [{ '_id' => '3' }] }, '_shards' => { 'failed' => 0 } }
    )
    client.expects(:scroll).with(scroll_id: 'second', scroll: '2m').returns(
      { '_scroll_id' => 'third', 'hits' => { 'hits' => [] }, '_shards' => { 'failed' => 0 } }
    )
    client.expects(:clear_scroll).with(body: { scroll_id: ['third'] })

    assert_equal [2, 3], ElasticsearchCodeSearch.search('a*b?c\\d', limit_to_ids: [2, 3])
  end

  test 'search reports incomplete results and releases the scroll' do
    Rails.logger.expects(:info).with(regexp_matches(/\AElasticsearch code search status=failed elapsed=\d+\.\d{3}s\z/))
    client = mock
    Searchkick.stubs(:client).returns(client)
    client.expects(:search).returns({ '_scroll_id' => 'first', 'timed_out' => true })
    client.expects(:clear_scroll).with(body: { scroll_id: ['first'] })

    assert_raises(RuntimeError) { ElasticsearchCodeSearch.search('test') }
  end

  test 'search rejects multiline queries and skips empty filters' do
    Rails.logger.expects(:info).never
    Searchkick.expects(:client).never
    assert_raises(ArgumentError) { ElasticsearchCodeSearch.search("a\nb", limit_to_ids: []) }
    assert_empty ElasticsearchCodeSearch.search('test', limit_to_ids: [])
  end

  test 'search logs failures from the initial Elasticsearch request' do
    Rails.logger.expects(:info).with(regexp_matches(/\AElasticsearch code search status=failed elapsed=\d+\.\d{3}s\z/))
    client = mock
    Searchkick.stubs(:client).returns(client)
    client.expects(:search).raises('connection failed')
    client.expects(:clear_scroll).never

    error = assert_raises(RuntimeError) { ElasticsearchCodeSearch.search('test') }
    assert_equal 'connection failed', error.message
  end

  test 'rebuild publishes only after all original code has been indexed' do
    client = mock
    indices = mock
    Searchkick.stubs(:client).returns(client)
    client.stubs(:indices).returns(indices)
    SecureRandom.stubs(:hex).returns('0123456789abcdef')
    new_index = "#{ElasticsearchCodeSearch.index_name}_0123456789abcdef"
    old_index = "#{ElasticsearchCodeSearch.index_name}_fedcba9876543210"
    Script.connection.stubs(:select_rows).returns([[1, 'original code']], [])
    Script.connection.stubs(:select_value).returns(1)
    sequence = sequence('rebuild')
    indices.expects(:create).with(index: new_index, body: anything).in_sequence(sequence)
    client.expects(:bulk).with(index: new_index, body: [{ index: { _id: 1 } }, { code: 'original code' }]).returns({ 'errors' => false }).in_sequence(sequence)
    indices.expects(:put_settings).in_sequence(sequence)
    indices.expects(:refresh).in_sequence(sequence)
    indices.expects(:exists_alias).returns(true).in_sequence(sequence)
    indices.expects(:get_alias).returns({ old_index => {} }).in_sequence(sequence)
    indices.expects(:update_aliases).with(body: { actions: [{ remove: { index: old_index, alias: ElasticsearchCodeSearch.index_name } }, { add: { index: new_index, alias: ElasticsearchCodeSearch.index_name } }] }).in_sequence(sequence)
    ElasticsearchCodeSearchCleanupJob.expects(:set).with(wait: 2.minutes).returns(stub(perform_later: nil))
    indices.expects(:delete).never

    ElasticsearchCodeSearch.index_all
  end

  test 'failed rebuild removes only the unpublished index' do
    client = mock
    indices = mock
    Searchkick.stubs(:client).returns(client)
    client.stubs(:indices).returns(indices)
    SecureRandom.stubs(:hex).returns('0123456789abcdef')
    new_index = "#{ElasticsearchCodeSearch.index_name}_0123456789abcdef"
    Script.connection.stubs(:select_rows).returns([[1, 'code']])
    Script.connection.stubs(:select_value).returns(1)
    indices.expects(:create)
    client.expects(:bulk).returns({ 'errors' => true, 'items' => [{ 'index' => { 'error' => 'bad code' } }] })
    indices.expects(:update_aliases).never
    indices.expects(:delete).with(index: new_index)

    assert_raises(RuntimeError) { ElasticsearchCodeSearch.index_all }
  end

  test 'rebuild refuses to run concurrently' do
    Script.connection.stubs(:select_value).returns(0)
    Searchkick.expects(:client).never

    error = assert_raises(ElasticsearchCodeSearch::AlreadyRunningError) { ElasticsearchCodeSearch.index_all }
    assert_includes error.message, 'already running'
  end

  test 'the database lock excludes concurrent rebuilds and updates' do
    options = Script.connection_db_config.configuration_hash.slice(:host, :username, :password, :database, :port, :socket)
    other_connection = Mysql2::Client.new(options)
    lock_name = Script.connection.quote(ElasticsearchCodeSearch.index_name)
    begin
      assert_equal 1, other_connection.query("SELECT GET_LOCK(#{lock_name}, 0)").first.values.first
      error = assert_raises(RuntimeError) { ElasticsearchCodeSearch.send(:with_index_lock, timeout: 0) { flunk 'Lock was acquired twice' } }
      assert_match(/already running/, error.message)
    ensure
      other_connection.query("SELECT RELEASE_LOCK(#{lock_name})")
      other_connection.close
    end
    assert_equal :acquired, ElasticsearchCodeSearch.send(:with_index_lock, timeout: 0) { :acquired }
  end

  test 'indexing reads the latest original code even for an older queued update' do
    script = scripts(:with_namespace)
    client = mock
    indices = mock
    Searchkick.stubs(:client).returns(client)
    client.stubs(:indices).returns(indices)
    indices.expects(:exists_alias).with(name: ElasticsearchCodeSearch.index_name).returns(true)
    client.expects(:index).with(index: ElasticsearchCodeSearch.index_name, id: script.id, require_alias: true, body: { code: script_codes(:four).code })

    ElasticsearchCodeSearch.index_script(script.id)
  end

  test 'indexing follows the latest version after creation and deletion' do
    script = scripts(:one)
    original = script.newest_saved_script_version
    code = ScriptCode.create!(code: 'new original code')
    version_id = ScriptVersion.insert_all!([{
                                             script_id: script.id,
                                             version: '2',
                                             script_code_id: code.id,
                                             rewritten_script_code_id: original.rewritten_script_code_id,
                                           }]).rows.first.first
    client = mock
    indices = mock
    Searchkick.stubs(:client).returns(client)
    client.stubs(:indices).returns(indices)
    indices.stubs(:exists_alias).returns(true)
    sequence = sequence('latest code')
    client.expects(:index).with(index: ElasticsearchCodeSearch.index_name, id: script.id, require_alias: true, body: { code: code.code }).in_sequence(sequence)
    client.expects(:index).with(index: ElasticsearchCodeSearch.index_name, id: script.id, require_alias: true, body: { code: original.code }).in_sequence(sequence)

    ElasticsearchCodeSearch.index_script(script.id)
    ScriptVersion.where(id: version_id).delete_all
    ElasticsearchCodeSearch.index_script(script.id)
  end

  test 'indexing removes a script with no versions' do
    client = mock
    indices = mock
    Searchkick.stubs(:client).returns(client)
    client.stubs(:indices).returns(indices)
    indices.expects(:exists_alias).returns(true)
    client.expects(:delete).with(index: ElasticsearchCodeSearch.index_name, id: -1, ignore: [404])

    ElasticsearchCodeSearch.index_script(-1)
  end

  test 'indexing reports a missing index instead of creating it' do
    client = mock
    indices = mock
    Searchkick.stubs(:client).returns(client)
    client.stubs(:indices).returns(indices)
    indices.expects(:exists_alias).returns(false)
    client.expects(:index).never

    assert_raises(RuntimeError) { ElasticsearchCodeSearch.index_script(scripts(:one).id) }
  end

  test 'old index cleanup waits for active search contexts' do
    old_index = "#{ElasticsearchCodeSearch.index_name}_fedcba9876543210"
    client = mock
    indices = mock
    Searchkick.stubs(:client).returns(client)
    client.stubs(:indices).returns(indices)
    indices.expects(:exists).with(index: old_index).returns(true)
    indices.expects(:exists_alias).with(index: old_index, name: ElasticsearchCodeSearch.index_name).returns(false)
    indices.expects(:stats).with(index: old_index, metric: 'search').returns({ '_all' => { 'total' => { 'search' => { 'open_contexts' => 1 } } } })
    ElasticsearchCodeSearchCleanupJob.expects(:set).with(wait: 2.minutes).returns(stub(perform_later: nil))
    indices.expects(:delete).never

    ElasticsearchCodeSearch.delete_old_index(old_index)
  end

  test 'old index cleanup deletes an idle index and rejects unexpected names' do
    old_index = "#{ElasticsearchCodeSearch.index_name}_fedcba9876543210"
    client = mock
    indices = mock
    Searchkick.stubs(:client).returns(client)
    client.stubs(:indices).returns(indices)
    indices.expects(:exists).returns(true)
    indices.expects(:exists_alias).returns(false)
    indices.expects(:stats).returns({ '_all' => { 'total' => { 'search' => { 'open_contexts' => 0 } } } })
    indices.expects(:delete).with(index: old_index)

    ElasticsearchCodeSearch.delete_old_index(old_index)
    assert_raises(RuntimeError) { ElasticsearchCodeSearch.delete_old_index('other_index') }
  end

  test 'old index cleanup never deletes the active index' do
    index = "#{ElasticsearchCodeSearch.index_name}_fedcba9876543210"
    client = mock
    indices = mock
    Searchkick.stubs(:client).returns(client)
    client.stubs(:indices).returns(indices)
    indices.expects(:exists).returns(true)
    indices.expects(:exists_alias).returns(true)
    indices.expects(:delete).never

    assert_raises(RuntimeError) { ElasticsearchCodeSearch.delete_old_index(index) }
  end
end
