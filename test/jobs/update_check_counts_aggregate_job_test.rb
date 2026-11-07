require 'test_helper'

class UpdateCheckCountsAggregateJobTest < ActiveSupport::TestCase
  test 'is scheduled at three minutes past the hour' do
    config = YAML.safe_load_file(Rails.root.join('config/sidekiq.yml'), permitted_classes: [Symbol])
    assert_equal '0 3 * * * *', config.fetch(:scheduler).fetch(:schedule).fetch('update_check_counts_aggregate_job').fetch('cron')
  end

  test 'aggregates per day, skips missing scripts, and clears old rows' do
    script = Script.first
    travel_to Time.utc(2026, 11, 6, 0, 3) do
      DailyUpdateCheckCount.insert_all!([
                                          { script_id: script.id, update_date: Time.utc(2026, 11, 5, 3), ip: '1.1.1.1' },
                                          { script_id: script.id, update_date: Time.utc(2026, 11, 5, 23), ip: '2.2.2.2' },
                                          { script_id: script.id, update_date: Time.utc(2026, 11, 6, 0), ip: '1.1.1.1' },
                                          { script_id: script.id, update_date: Time.utc(2026, 11, 4, 12), ip: '3.3.3.3' },
                                          { script_id: script.id + 100_000, update_date: Time.utc(2026, 11, 5, 3), ip: '1.1.1.1' },
                                        ])
      UpdateCheckCountsAggregateJob.new.perform
    end
    assert_equal 2, UpdateCheckCount.find_by!(script_id: script.id, update_check_date: '2026-11-05').update_checks
    assert_equal 1, UpdateCheckCount.find_by!(script_id: script.id, update_check_date: '2026-11-06').update_checks
    assert_equal 1, UpdateCheckCount.find_by!(script_id: script.id, update_check_date: '2026-11-04').update_checks
    assert_equal 4, DailyUpdateCheckCount.count
  end

  test 'retains raw rows if the aggregate write fails' do
    travel_to Time.utc(2026, 11, 7, 1, 3) do
      DailyUpdateCheckCount.create!(script_id: Script.first.id, update_date: Time.utc(2026, 11, 5, 3), ip: '1.1.1.1')
      UpdateCheckCount.expects(:upsert_all).raises('write failed')

      assert_raises(RuntimeError) { UpdateCheckCountsAggregateJob.new.perform }
      assert_equal 1, DailyUpdateCheckCount.count
    end
  end

  test 'clears the previous day after the final hourly import' do
    travel_to Time.utc(2026, 11, 6, 1, 3) do
      script = Script.first
      DailyUpdateCheckCount.create!(script_id: script.id, update_date: Time.utc(2026, 11, 5, 23), ip: '1.1.1.1')
      DailyUpdateCheckCount.create!(script_id: script.id, update_date: Time.utc(2026, 11, 6, 0), ip: '1.1.1.1')

      UpdateCheckCountsAggregateJob.new.perform

      assert_equal 1, UpdateCheckCount.find_by!(script_id: script.id, update_check_date: '2026-11-05').update_checks
      assert_equal [Date.new(2026, 11, 6)], DailyUpdateCheckCount.distinct.pluck(:update_day)
    end
  end

  test 'same IP on consecutive days is counted each day' do
    script = Script.first
    DailyUpdateCheckCount.insert_all!([
                                        { script_id: script.id, update_date: Time.utc(2026, 11, 5, 23, 30), ip: '1.1.1.1' },
                                        { script_id: script.id, update_date: Time.utc(2026, 11, 6, 0, 30), ip: '1.1.1.1' },
                                      ])
    assert_equal 2, DailyUpdateCheckCount.count
  end

  test 'destroying a script deletes its update check counts' do
    script = Script.first
    UpdateCheckCount.create!(script_id: script.id, update_check_date: '2026-11-05', update_checks: 5)
    DailyUpdateCheckCount.create!(script_id: script.id, update_date: Time.utc(2026, 11, 5, 3), ip: '1.1.1.1')
    script.destroy!
    assert_not UpdateCheckCount.exists?(script_id: script.id)
    assert_not DailyUpdateCheckCount.exists?(script_id: script.id)
  end
end
