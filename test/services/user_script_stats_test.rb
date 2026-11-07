require 'test_helper'

class UserScriptStatsTest < ActiveSupport::TestCase
  test 'batch stats match individual stats for all subsets and shared authors' do
    scripts(:one).update_columns(sensitive: true, daily_installs: 7, total_installs: 42, good_ratings: 3, ok_ratings: 2, bad_ratings: 1)
    scripts(:two).update_columns(daily_installs: 4, total_installs: 20, good_ratings: 1)
    scripts(:three).update_columns(delete_type: Script.delete_types.fetch('keep'))
    scripts(:script_with_generated_version).update_columns(review_state: 'required')
    Author.create!(user: users(:mod), script: scripts(:unlisted))
    authors = [users(:one), users(:geoff), users(:mod)]
    expected = authors.index_with(&:calculate_stats).transform_keys(&:id)
    queries = []
    subscriber = ->(_name, _start, _finish, _id, payload) { queries << payload[:sql] unless payload[:name] == 'SCHEMA' }

    actual = ActiveSupport::Notifications.subscribed(subscriber, 'sql.active_record') do
      UserScriptStats.for_users(authors.map(&:id))
    end

    assert_equal expected, actual
    assert_equal 3, queries.size
    assert_operator actual[users(:one).id][:sleazyfork_script_count], :>, 0
    assert_equal 4, actual[users(:geoff).id][:all_script_daily_installs]
    assert_equal User::NO_SCRIPT_STATS_TEMPLATE, actual[users(:mod).id]
  end

  test 'empty input does not query' do
    Script.expects(:listable).never
    assert_empty UserScriptStats.for_users([])
  end
end
