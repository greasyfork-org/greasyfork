require 'test_helper'

class ScriptsHelperTest < ActionView::TestCase
  include ScriptsHelper

  def request_locale
    Locale.find_by!(code: 'en')
  end

  test 'common source truncation note is nil when nothing was omitted' do
    section = { omitted_lines: 0, omitted_bytes: 0 }
    match = { script: [section], other_script: [section] }

    assert_nil common_source_truncation_note(match)
  end

  test 'common source truncation note reports the larger omission' do
    match = {
      script: [{ omitted_lines: 1, omitted_bytes: 2048 }],
      other_script: [{ omitted_lines: 200, omitted_bytes: 4096 }],
    }

    assert_equal '200 lines (4 KB) omitted.', common_source_truncation_note(match)
  end
end
