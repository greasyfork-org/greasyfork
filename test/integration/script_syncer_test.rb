require 'test_helper'
require 'script_importer/url_importer'
require 'script_importer/script_syncer'
class ScriptSyncerTest < ActiveSupport::TestCase
  include ScriptImporter

  test 'sync' do
    script = Script.find(7)
    assert_equal 1, script.script_versions.length
    assert_equal :success, ScriptSyncer.sync(script)
    assert_equal 'A Test!', script.name
    assert_equal Time.now.utc.to_date, script.code_updated_at.to_date
    assert_equal Time.now.utc.to_date, script.last_attempted_sync_date.to_date
    assert_equal Time.now.utc.to_date, script.last_successful_sync_date.to_date
    assert_nil script.sync_error
    assert_equal 2, script.script_versions.length
  end

  test 'unchanged' do
    script = Script.find(8)
    assert_equal 1, script.script_versions.length
    assert_equal :unchanged, ScriptSyncer.sync(script)
    assert_equal '2000-01-01', script.code_updated_at.to_date.to_s
    assert_equal Time.now.utc.to_date, script.last_attempted_sync_date.to_date
    assert_equal Time.now.utc.to_date, script.last_successful_sync_date.to_date
    assert_nil script.sync_error
    assert_equal 1, script.script_versions.length
  end

  test 'keep old description' do
    script = Script.find(9)
    assert_equal 1, script.script_versions.length
    assert_equal :success, ScriptSyncer.sync(script), script.sync_error
    assert_equal Time.now.utc.to_date, script.code_updated_at.to_date.to_date
    assert_equal Time.now.utc.to_date, script.last_attempted_sync_date.to_date
    assert_equal Time.now.utc.to_date, script.last_successful_sync_date.to_date
    assert_nil script.sync_error
    assert_equal 'Unit test.', script.description
    assert_equal 2, script.script_versions.length
    old_code = script.script_versions.last.code
    r = ScriptSyncer.sync(script)
    new_code = script.script_versions.last.code
    assert_equal old_code, new_code
    assert_equal :unchanged, r, r
    assert_equal 2, script.script_versions.length
  end

  test 'new version invalid' do
    script = Script.find(10)
    assert_equal 1, script.script_versions.length
    assert_equal :failure, ScriptSyncer.sync(script)
    assert_equal '2000-01-01', script.code_updated_at.to_date.to_s
    assert_equal Time.now.utc.to_date, script.last_attempted_sync_date.to_date
    assert_equal '2000-01-01', script.last_successful_sync_date.to_date.to_s
    assert_not_nil script.sync_error
    assert_equal 1, script.script_versions.length
  end

  test 'keep old additional info' do
    script = Script.find(7)
    assert_equal 1, script.script_versions.length
    assert_equal 'MyText', script.script_versions.last.additional_info
    assert_equal 'MyText', script.additional_info
    assert_equal 'markdown', script.script_versions.last.localized_attributes_for('additional_info').first.value_markup
    assert_equal 'markdown', script.localized_attributes_for('additional_info').last.value_markup
    # after the sync, the additional info should be unchanged
    assert_equal :success, ScriptSyncer.sync(script), script.sync_error
    assert_equal 2, script.script_versions.length
    assert_equal 'MyText', script.script_versions.last.additional_info
    assert_equal 'MyText', script.additional_info
    assert_equal 'markdown', script.script_versions.last.localized_attributes_for('additional_info').first.value_markup
    assert_equal 'markdown', script.localized_attributes_for('additional_info').last.value_markup
  end

  test 'long changelog' do
    script = Script.find(7)
    assert_equal 1, script.script_versions.length
    assert_equal :success, ScriptSyncer.sync(script, 'a' * 1000), script.sync_error
    assert_equal 'A Test!', script.name
    assert_equal Time.now.utc.to_date, script.code_updated_at.to_date
    assert_equal Time.now.utc.to_date, script.last_attempted_sync_date.to_date
    assert_equal Time.now.utc.to_date, script.last_successful_sync_date.to_date
    assert_equal "#{'a' * 497}...", script.script_versions.last.changelog
    assert_nil script.sync_error
    assert_equal 2, script.script_versions.length
  end

  test 'additional info sync' do
    script = Script.find(14)
    assert script.valid?, script.errors.full_messages
    assert_equal 1, script.script_versions.length
    assert script.script_versions.first.valid?, script.script_versions.first.errors.full_messages
    assert_equal 2, script.localized_attributes_for('additional_info').length, script.localized_attributes_for('additional_info')
    assert script.localized_attributes_for('additional_info').all? { |la| !la.sync_identifier.nil? }, script.localized_attributes_for('additional_info').inspect

    assert_equal :success, ScriptSyncer.sync(script), script.sync_error

    assert_equal 2, script.script_versions.length

    en_ai = script.localized_attributes_for('additional_info').find { |la| la.locale == Locale.where(code: 'en').first }
    assert_not_nil en_ai
    assert_equal 'MyNewText', en_ai.attribute_value
    assert_not_nil en_ai.sync_identifier

    fr_ai = script.localized_attributes_for('additional_info').find { |la| la.locale == Locale.where(code: 'fr').first }
    assert_not_nil fr_ai
    assert_equal 'MonNouveauTexte', fr_ai.attribute_value
    assert_not_nil fr_ai.sync_identifier
  end

  test 'additional info sync retain unsynced' do
    script = Script.find(14)
    assert script.valid?, script.errors.full_messages
    assert_equal 1, script.script_versions.length
    assert script.script_versions.first.valid?, script.script_versions.first.errors.full_messages
    assert_equal 2, script.localized_attributes_for('additional_info').length, script.localized_attributes_for('additional_info')
    assert script.localized_attributes_for('additional_info').all? { |la| !la.sync_identifier.nil? }, script.localized_attributes_for('additional_info').inspect

    # take off syncing from the french one
    french_la = script.localized_attributes_for('additional_info').find { |la| la.locale == Locale.where(code: 'fr').first }
    french_la.sync_identifier = nil

    assert_equal :success, ScriptSyncer.sync(script), script.sync_error

    assert_equal 2, script.script_versions.length

    # english should be updated
    en_ai = script.localized_attributes_for('additional_info').find { |la| la.locale == Locale.where(code: 'en').first }
    assert_not_nil en_ai
    assert_equal 'MyNewText', en_ai.attribute_value
    assert_not_nil en_ai.sync_identifier

    # french should still be there and unchanged
    fr_ai = script.localized_attributes_for('additional_info').find { |la| la.locale == Locale.where(code: 'fr').first }
    assert_not_nil fr_ai
    assert_equal 'MonTexte', fr_ai.attribute_value
    assert_nil fr_ai.sync_identifier
  end

  test 'additional info change only is success' do
    script = Script.find(14)
    assert script.valid?, script.errors.full_messages
    assert_equal 1, script.script_versions.length
    assert script.script_versions.first.valid?, script.script_versions.first.errors.full_messages
    assert_equal 2, script.localized_attributes_for('additional_info').length, script.localized_attributes_for('additional_info')
    assert script.localized_attributes_for('additional_info').all? { |la| !la.sync_identifier.nil? }, script.localized_attributes_for('additional_info').inspect

    # ensure the code won't change on sync
    script.sync_identifier = script.script_versions.first.code

    assert_equal :success, ScriptSyncer.sync(script), script.sync_error

    en_ai = script.localized_attributes_for('additional_info').find { |la| la.locale == Locale.where(code: 'en').first }
    assert_not_nil en_ai
    assert_equal 'MyNewText', en_ai.attribute_value
    assert_not_nil en_ai.sync_identifier

    fr_ai = script.localized_attributes_for('additional_info').find { |la| la.locale == Locale.where(code: 'fr').first }
    assert_not_nil fr_ai
    assert_equal 'MonNouveauTexte', fr_ai.attribute_value
    assert_not_nil fr_ai.sync_identifier
  end

  test 'keep attachments' do
    script = Script.find(17)
    assert_equal 1, script.script_versions.length
    script.script_versions.first.attachments.attach(io: Rails.root.join('test/fixtures/files/blacklogo16.png').open, filename: 'blacklogo16.png', content_type: 'image/png')
    assert_equal 1, script.script_versions.first.attachments.length
    assert_equal :success, ScriptSyncer.sync(script)
    assert_equal 2, script.script_versions.length
    assert_equal 1, script.script_versions.first.attachments.length
    assert_equal 1, script.script_versions.last.attachments.length
  end

  test 'sync library' do
    script = scripts(:library)
    assert_equal 1, script.script_versions.length
    assert_equal :success, ScriptSyncer.sync(script), script.reload.sync_error
    assert_equal 'jQuery', script.name
    assert_equal Time.now.utc.to_date, script.code_updated_at.to_date
    assert_equal Time.now.utc.to_date, script.last_attempted_sync_date.to_date
    assert_equal Time.now.utc.to_date, script.last_successful_sync_date.to_date
    assert_nil script.sync_error
    assert_equal 2, script.script_versions.length
  end
end
