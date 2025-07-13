require 'test_helper'

class ScriptVersionCompareNumbersTest < ActiveSupport::TestCase
  test 'compare' do
    # This is a 2d array - the outer dimension reflects increasing version numbers,
    # the inner dimension reflects equal version numbers. Originally taken from
    # https://developer.mozilla.org/en-US/docs/Toolkit_version_format#Examples
    # with "pre", "*", and "+" examples removed.
    strings_to_test = [
      ['Alpha-v1'],
      ['Alpha-v10'], # matches greasemonkey
      ['Alpha-v2'],
      ['1.-1'],
      ['1', '1.', '1.0', '1.0.0'],
      ['1.1a'],
      ['1.1aa'],
      ['1.1ab'],
      ['1.1b'],
      ['1.1c'],
      ['1.1.-1'],
      ['1.1', '1.1.0', '1.1.00'],
      # this is a consequence of us stopping at 4 dots and the "any string is less than
      # empty string" rule
      ['1.1.1.1.1'],
      ['1.1.1.1.2'],
      ['1.1.1.1'],
      ['1.10'],
      ['2.0'],
    ]
    # make sure each step is smaller than the next
    (0..(strings_to_test.length - 2)).each do |i|
      strings_to_test[i].product(strings_to_test[i + 1]).each do |vs|
        assert_equal(-1, ScriptVersion.compare_versions(vs[0], vs[1]), "compare_versions('#{vs[0]}', '#{vs[1]}')")
      end
    end
    # make sure within each step is equal
    strings_to_test.each do |equivalent_strings|
      equivalent_strings.combination(2).each do |vs|
        assert_equal 0, ScriptVersion.compare_versions(vs[0], vs[1]), "compare_versions('#{vs[0]}', '#{vs[1]}')"
      end
    end
  end
end
