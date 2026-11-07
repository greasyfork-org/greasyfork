require 'test_helper'
require 'stringio'

class ScriptStatsTimingTest < ActiveSupport::TestCase
  test 'logs monotonic elapsed time and returns the result' do
    output = StringIO.new
    ScriptStatsTiming.stubs(:logger).returns(Logger.new(output))
    Process.expects(:clock_gettime).with(Process::CLOCK_MONOTONIC).twice.returns(10.0, 12.345)

    assert_equal :result, ScriptStatsTiming.measure('test step') { :result }
    assert_match(/test step status=completed elapsed=2\.345s/, output.string)
  end

  test 'logs failures and propagates the original exception' do
    output = StringIO.new
    ScriptStatsTiming.stubs(:logger).returns(Logger.new(output))

    error = assert_raises(RuntimeError) { ScriptStatsTiming.measure('test step') { raise 'failure' } }
    assert_equal 'failure', error.message
    assert_match(/test step status=failed elapsed=\d+\.\d{3}s/, output.string)
  end
end
