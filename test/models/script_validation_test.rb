require 'test_helper'

class ScriptValidationTest < ActiveSupport::TestCase
  def get_script_with_code(code)
    script = valid_script
    sv = script.script_versions.first
    script.script_versions.first.code = code
    sv.calculate_all
    script.apply_from_script_version(sv)
    script
  end

  test 'name length' do
    script = get_script_with_code(<<~JS)
      // ==UserScript==
      // @name		#{'1' * 600}
      // @description		description
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include *
      // ==/UserScript==
      foo.baz();
    JS
    assert script.name.length > 500
    assert_not script.valid?
    assert_equal(1, script.errors.to_a.length, script.errors.full_messages)
    assert_includes script.errors.full_messages.first, '@name', script.errors.full_messages
  end

  test 'description length' do
    script = get_script_with_code(<<~JS)
      // ==UserScript==
      // @name		A Test!
      // @description		#{'1' * 600}
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include *
      // ==/UserScript==
      foo.baz();
    JS
    assert script.description.length > 500
    assert_not script.valid?
    assert_equal(1, script.errors.to_a.length, script.errors.full_messages)
    assert_includes script.errors.full_messages.first, '@description', script.errors.full_messages
  end

  test 'additional info length' do
    script = valid_script
    sv = script.script_versions.first
    sv.localized_attributes.build(attribute_key: 'additional_info', attribute_value: '1' * 60_000, locale: Locale.english, value_markup: 'html')
    sv.calculate_all
    script.apply_from_script_version(sv)
    assert_not script.valid?
    assert_equal(1, script.errors.to_a.length, script.errors.full_messages)
    assert_includes script.errors.full_messages.first, 'Additional info', script.errors.full_messages
  end

  test 'localized additional info without a name in that locale' do
    script = valid_script
    sv = script.script_versions.first
    sv.localized_attributes.build(attribute_key: 'additional_info', attribute_value: 'ouin', locale: locales(:french), value_markup: 'html')
    sv.calculate_all
    script.apply_from_script_version(sv)
    assert_not sv.valid?
    assert_equal(1, sv.errors.to_a.length, sv.errors.full_messages)
    assert_includes sv.errors.full_messages.first, 'Additional info was specified', sv.errors.full_messages
  end

  test 'localized additional info locale repeated' do
    script = valid_script
    sv = script.script_versions.first
    sv.localized_attributes.build(attribute_key: 'additional_info', attribute_value: 'ouin', locale: Locale.english, value_markup: 'html')
    sv.localized_attributes.build(attribute_key: 'additional_info', attribute_value: 'ouin', locale: Locale.english, value_markup: 'html')
    sv.calculate_all
    script.apply_from_script_version(sv)
    assert_not sv.valid?
    assert_equal(1, sv.errors.to_a.length, sv.errors.full_messages)
    assert_includes sv.errors.full_messages.first, 'Provide only one additional info', sv.errors.full_messages
  end

  test 'localized meta duplicates default' do
    script = get_script_with_code(<<~JS)
      // ==UserScript==
      // @name		My script name
      // @name:en My script name in English
      // @description		My description
      // @description:en My description in English
      // @version 1.0
      // @namespace http://greasyfork.local/users/1
      // @include *
      // ==/UserScript==
      foo.baz();
    JS
    sv = script.script_versions.first
    sv.calculate_all
    script.apply_from_script_version(sv)
    assert_not sv.valid?
    assert_includes sv.errors.full_messages.first, "Code should not specify @name:en as 'en' is the default locale.", sv.errors.full_messages
    assert_includes sv.errors.full_messages.second, "Code should not specify @description:en as 'en' is the default locale.", sv.errors.full_messages
  end
end
