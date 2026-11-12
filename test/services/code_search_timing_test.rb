require 'test_helper'

class CodeSearchTimingTest < ActiveSupport::TestCase
  test 'logs elapsed monotonic time and returns the result' do
    timing = CodeSearchTiming
    Process.expects(:clock_gettime).with(Process::CLOCK_MONOTONIC).twice.returns(10.0, 12.345)
    Rails.logger.expects(:info).with('grep code search status=completed elapsed=2.345s')

    assert_equal :result, timing.measure('grep') { :result }
  end

  test 'logs elapsed time and preserves errors' do
    Rails.logger.expects(:info).with(regexp_matches(/\AElasticsearch code search status=failed elapsed=\d+\.\d{3}s\z/))

    error = assert_raises(RuntimeError) { CodeSearchTiming.measure('Elasticsearch') { raise 'search error' } }
    assert_equal 'search error', error.message
  end
end
