require 'test_helper'

class ScriptAntifeatureTest < ActiveSupport::TestCase
  test 'simple' do
    script = valid_script
    sv = ScriptVersion.new
    sv.script = script
    sv.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.1
      // @namespace http://greasyfork.local/users/1
      // @antifeature ads We show you ads.
      // @include *
      // ==/UserScript==
      var foo = 2;
    JS
    sv.calculate_all
    script.apply_from_script_version(sv)
    assert_equal 1, script.antifeatures.length
    af = script.antifeatures.first
    assert_nil af.locale
    assert_equal 'ads', af.antifeature_type
    assert_equal 'We show you ads.', af.description
    sv.save!
    script.save!
    assert_equal 1, Script.find(script.id).antifeatures.length
  end

  test 'localized' do
    script = valid_script
    sv = ScriptVersion.new
    sv.script = script
    sv.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.1
      // @namespace http://greasyfork.local/users/1
      // @antifeature:en ads We show you ads.
      // @include *
      // ==/UserScript==
      var foo = 2;
    JS
    sv.calculate_all
    script.apply_from_script_version(sv)
    assert_equal 1, script.antifeatures.length
    af = script.antifeatures.first
    assert_equal Locale.english, af.locale
    assert_equal 'ads', af.antifeature_type
    assert_equal 'We show you ads.', af.description
    sv.save!
    script.save!
    assert_equal 1, Script.find(script.id).antifeatures.length
  end

  test 'multiple localized' do
    script = valid_script
    sv = ScriptVersion.new
    sv.script = script
    sv.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.1
      // @namespace http://greasyfork.local/users/1
      // @antifeature ads We show you ads.
      // @antifeature:fr ads We show you ads hon hon.
      // @antifeature:es ads We show you ads jeje.
      // @include *
      // ==/UserScript==
      var foo = 2;
    JS
    sv.calculate_all
    script.apply_from_script_version(sv)
    assert_equal 3, script.antifeatures.length
    sv.save!
    script.save!
    assert_equal 3, Script.find(script.id).antifeatures.length
    assert_equal 'We show you ads.', script.antifeatures.find_by(locale: nil).description
    assert_equal 'We show you ads hon hon.', script.antifeatures.find_by(locale: Locale.find_by!(code: 'fr')).description
    assert_equal 'We show you ads jeje.', script.antifeatures.find_by(locale: Locale.find_by!(code: 'es')).description
  end

  test 'multiple types' do
    script = valid_script
    sv = ScriptVersion.new
    sv.script = script
    sv.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.1
      // @namespace http://greasyfork.local/users/1
      // @antifeature ads We show you ads.
      // @antifeature tracking We track you.
      // @include *
      // ==/UserScript==
      var foo = 2;
    JS
    sv.calculate_all
    script.apply_from_script_version(sv)
    assert_equal 2, script.antifeatures.length
    sv.save!
    script.save!
    assert_equal 2, Script.find(script.id).antifeatures.length
    assert_equal 'We show you ads.', script.antifeatures.ads.first.description
    assert_equal 'We track you.', script.antifeatures.tracking.first.description
  end

  test 'unknown type is ignored' do
    script = valid_script
    sv = ScriptVersion.new
    sv.script = script
    sv.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.1
      // @namespace http://greasyfork.local/users/1
      // @antifeature hacking We hack you.
      // @include *
      // ==/UserScript==
      var foo = 2;
    JS
    sv.calculate_all
    script.apply_from_script_version(sv)
    assert_empty script.antifeatures
    sv.save!
    script.save!
    assert_empty Script.find(script.id).antifeatures
  end

  test 'no description' do
    script = valid_script
    sv = ScriptVersion.new
    sv.script = script
    sv.code = <<~JS
      // ==UserScript==
      // @name		A Test!
      // @description		Unit test.
      // @version 1.1
      // @namespace http://greasyfork.local/users/1
      // @antifeature ads
      // @include *
      // ==/UserScript==
      var foo = 2;
    JS
    sv.calculate_all
    script.apply_from_script_version(sv)
    assert_equal 1, script.antifeatures.length
    af = script.antifeatures.first
    assert_nil af.locale
    assert_equal 'ads', af.antifeature_type
    assert_nil af.description
    sv.save!
    script.save!
    assert_equal 1, Script.find(script.id).antifeatures.length
  end
end
