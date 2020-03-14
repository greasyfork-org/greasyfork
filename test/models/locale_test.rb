require 'test_helper'

class LocaleTest < ActiveSupport::TestCase
  test 'matching locale generic exact match' do
    l = Locale.matching_locales('en')
    assert_equal 1, l.length
    assert_equal 'English', l.first.english_name
  end

  test 'matching locale country matches generic' do
    l = Locale.matching_locales('en-US')
    assert_equal 1, l.length
    assert_equal 'English', l.first.english_name
  end

  test 'matching locale country exact match' do
    l = Locale.matching_locales('zh-TW')
    assert_equal 1, l.length
    assert_equal 'Chinese (Traditional)', l.first.english_name
  end

  test 'matching locale generic matches country' do
    l = Locale.matching_locales('zh')
    assert_equal 2, l.length
    assert_equal 'Chinese (Simplified)', l[0].english_name
    assert_equal 'Chinese (Traditional)', l[1].english_name
  end

  test 'matching locale different country' do
    l = Locale.matching_locales('zh-XX')
    assert_equal 2, l.length
    assert_equal 'Chinese (Simplified)', l[0].english_name
    assert_equal 'Chinese (Traditional)', l[1].english_name
  end

  test 'matching locale no match' do
    l = Locale.matching_locales('xx')
    assert_empty l
  end

  test 'matching locale no match with country' do
    l = Locale.matching_locales('xx-XX')
    assert_empty l
  end
end
