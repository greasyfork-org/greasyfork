require 'test_helper'
require 'stringio'

class UpdateInstallCountsJobTest < ActiveSupport::TestCase
  setup do
    @connection = ApplicationRecord.connection
    @script = scripts(:one)
    @banned = scripts(:two)
    @expired = scripts(:three)
    @empty = scripts(:script_with_generated_version)
  end

  test 'rolls up installs, applies bans, resets stale counts, and reindexes once' do
    @connection.execute("INSERT INTO install_counts (script_id, install_date, installs) VALUES (#{@script.id}, DATE_SUB(CURDATE(), INTERVAL 3 DAY), 7), (#{@banned.id}, DATE_SUB(CURDATE(), INTERVAL 3 DAY), 5)")
    add_install(@script, '1.1.1.1', 'DATE_SUB(CURDATE(), INTERVAL 3 DAY)')
    add_install(@script, '1.1.1.2', 'DATE_SUB(CURDATE(), INTERVAL 3 DAY)')
    add_install(@script, '1.1.1.3', 'DATE_SUB(NOW(), INTERVAL 25 HOUR)')
    add_install(@script, '1.1.1.4', 'DATE_SUB(NOW(), INTERVAL 23 HOUR)')
    add_install(@banned, '2.2.2.2', 'NOW()')
    add_install(@expired, '3.3.3.3', 'NOW()')
    StatBan.create!(script: @banned, expires_at: 1.day.from_now)
    StatBan.create!(script: @expired, expires_at: 1.day.ago)
    @empty.update_columns(daily_installs: 10, total_installs: 20)
    Script.expects(:reindex).twice

    UpdateInstallCountsJob.new.perform
    assert_equal [1, 11], @script.reload.attributes.values_at('daily_installs', 'total_installs')
    assert_equal [0, 5], @banned.reload.attributes.values_at('daily_installs', 'total_installs')
    assert_equal [1, 1], @expired.reload.attributes.values_at('daily_installs', 'total_installs')
    assert_equal [0, 0], @empty.reload.attributes.values_at('daily_installs', 'total_installs')
    assert_equal 9, @connection.select_value("SELECT installs FROM install_counts WHERE script_id = #{@script.id} AND install_date = DATE_SUB(CURDATE(), INTERVAL 3 DAY)")
    assert_equal 0, @connection.select_value("SELECT COUNT(*) FROM daily_install_counts WHERE script_id = #{@banned.id}")
    assert_equal 0, @connection.select_value('SELECT COUNT(*) FROM daily_install_counts WHERE install_date < DATE_SUB(CURDATE(), INTERVAL 1 DAY)')

    UpdateInstallCountsJob.new.perform
    assert_equal [1, 11], @script.reload.attributes.values_at('daily_installs', 'total_installs')
    assert_equal 9, @connection.select_value("SELECT installs FROM install_counts WHERE script_id = #{@script.id} AND install_date = DATE_SUB(CURDATE(), INTERVAL 3 DAY)")
  end

  test 'rollup and deletion roll back together on failure' do
    add_install(@script, '1.1.1.1', 'DATE_SUB(CURDATE(), INTERVAL 2 DAY)')
    job = UpdateInstallCountsJob.new
    roll_up = job.method(:roll_up_installs)
    job.define_singleton_method(:roll_up_installs) do |*args|
      roll_up.call(*args)
      raise 'failed after rollup'
    end
    Script.expects(:reindex).once

    assert_raises(RuntimeError) { job.perform }
    assert_equal 1, @connection.select_value("SELECT COUNT(*) FROM daily_install_counts WHERE script_id = #{@script.id}")
    assert_equal 0, @connection.select_value("SELECT COUNT(*) FROM install_counts WHERE script_id = #{@script.id}")
    assert_equal [0, 0], @script.reload.attributes.values_at('daily_installs', 'total_installs')

    UpdateInstallCountsJob.new.perform
    assert_equal [0, 1], @script.reload.attributes.values_at('daily_installs', 'total_installs')
  end

  test 'uses inclusive daily and exclusive historical cutoffs' do
    add_install(@script, '1.1.1.1', "'2026-11-05 23:59:59'")
    add_install(@script, '1.1.1.2', "'2026-11-06 00:00:00'")
    add_install(@script, '1.1.1.3', "'2026-11-06 11:59:59'")
    add_install(@script, '1.1.1.4', "'2026-11-06 12:00:00'")
    @connection.expects(:select_one).with(includes('AS run_time')).returns(
      'run_time' => Time.utc(2026, 11, 7, 12),
      'daily_cutoff' => Time.utc(2026, 11, 6, 12),
      'historical_cutoff' => Date.new(2026, 11, 6)
    )
    Script.expects(:reindex).once

    UpdateInstallCountsJob.new.perform
    assert_equal [1, 4], @script.reload.attributes.values_at('daily_installs', 'total_installs')
    assert_equal 1, @connection.select_value("SELECT installs FROM install_counts WHERE script_id = #{@script.id} AND install_date = '2026-11-05'")
    assert_equal 3, @connection.select_value("SELECT COUNT(*) FROM daily_install_counts WHERE script_id = #{@script.id}")
  end

  test 'retry after a reindex failure does not count rolled-up installs twice' do
    add_install(@script, '1.1.1.1', 'DATE_SUB(CURDATE(), INTERVAL 3 DAY)')
    Script.expects(:reindex).twice.raises('reindex failed').then.returns(nil)

    assert_raises(RuntimeError) { UpdateInstallCountsJob.new.perform }
    UpdateInstallCountsJob.new.perform
    assert_equal [0, 1], @script.reload.attributes.values_at('daily_installs', 'total_installs')
    assert_equal 1, @connection.select_value("SELECT installs FROM install_counts WHERE script_id = #{@script.id}")
  end

  test 'retry after a later batch fails preserves committed rollups' do
    output = StringIO.new
    ScriptStatsTiming.stubs(:logger).returns(Logger.new(output))
    first, second = Script.order(:id).limit(2).to_a
    add_install(first, '1.1.1.1', 'DATE_SUB(CURDATE(), INTERVAL 3 DAY)')
    add_install(second, '1.1.1.2', 'DATE_SUB(CURDATE(), INTERVAL 3 DAY)')
    job = UpdateInstallCountsJob.new
    roll_up = job.method(:roll_up_installs)
    batches = 0
    job.define_singleton_method(:roll_up_installs) do |*args|
      roll_up.call(*args)
      batches += 1
      raise 'failed after second rollup' if batches == 2
    end
    Script.expects(:reindex).once

    stub_const(UpdateInstallCountsJob, :BATCH_SIZE, 1) do
      assert_raises(RuntimeError) { job.perform }
      assert_match(/UpdateInstallCountsJob batch #{second.id}-#{second.id} status=failed elapsed=\d+\.\d{3}s/, output.string)
      assert_match(/UpdateInstallCountsJob process batches status=failed elapsed=\d+\.\d{3}s/, output.string)
      assert_match(/UpdateInstallCountsJob drop temporary table status=completed elapsed=\d+\.\d{3}s/, output.string)
      assert_equal 1, @connection.select_value("SELECT COUNT(*) FROM install_counts WHERE script_id = #{first.id}")
      assert_equal 1, @connection.select_value("SELECT COUNT(*) FROM daily_install_counts WHERE script_id = #{second.id}")
      UpdateInstallCountsJob.new.perform
    end

    assert_equal [0, 1], first.reload.attributes.values_at('daily_installs', 'total_installs')
    assert_equal [0, 1], second.reload.attributes.values_at('daily_installs', 'total_installs')
    assert_equal 2, @connection.select_value("SELECT SUM(installs) FROM install_counts WHERE script_id IN (#{first.id}, #{second.id})")
  end

  test 'processes multiple batches' do
    output = StringIO.new
    ScriptStatsTiming.stubs(:logger).returns(Logger.new(output))
    @connection.execute("INSERT INTO install_counts (script_id, install_date, installs) VALUES (#{@script.id}, DATE_SUB(CURDATE(), INTERVAL 3 DAY), 7)")
    add_install(@script, '1.1.1.1', 'NOW()')
    add_install(@script, '1.1.1.2', 'DATE_SUB(CURDATE(), INTERVAL 3 DAY)')
    add_install(@expired, '3.3.3.3', 'NOW()')
    add_install(@banned, '2.2.2.2', 'NOW()')
    StatBan.create!(script: @banned, expires_at: 1.day.from_now)
    Script.expects(:reindex).once

    statements = []
    subscriber = ->(_name, _start, _finish, _id, payload) { statements << payload[:sql] }
    ActiveSupport::Notifications.subscribed(subscriber, 'sql.active_record') do
      stub_const(UpdateInstallCountsJob, :BATCH_SIZE, 2) do
        UpdateInstallCountsJob.new.perform
      end
    end
    assert_equal [1, 9], @script.reload.attributes.values_at('daily_installs', 'total_installs')
    assert_equal [1, 1], @expired.reload.attributes.values_at('daily_installs', 'total_installs')
    assert_equal [0, 0], @banned.reload.attributes.values_at('daily_installs', 'total_installs')
    historical_queries = statements.count { |sql| sql.include?('FROM install_counts IGNORE INDEX') }
    ban_deletions = statements.count { |sql| sql.start_with?('DELETE daily_install_counts FROM') }
    assert_equal 1, historical_queries
    assert_equal 1, ban_deletions
    [
      'select cutoffs', 'prepare historical counts', 'create historical totals table',
      'select historical totals', 'insert historical totals', 'delete banned installs',
      'process batches', 'drop temporary table', 'reindex'
    ].each do |step|
      assert_match(/UpdateInstallCountsJob #{step} status=completed elapsed=\d+\.\d{3}s/, output.string)
    end
    ['update script counts', 'roll up installs', 'insert rollups', 'delete rolled-up installs'].each do |step|
      assert_operator output.string.scan(/UpdateInstallCountsJob batch \d+-\d+ #{step} status=completed elapsed=\d+\.\d{3}s/).size, :>=, 2
    end
  end

  private

  def add_install(script, ip, install_date)
    @connection.execute("INSERT INTO daily_install_counts (script_id, ip, install_date) VALUES (#{script.id}, #{@connection.quote(ip)}, #{install_date})")
  end
end
