require 'test_helper'
require 'tmpdir'

class ScriptCodeSearchTest < ActiveSupport::TestCase
  test 'index all and incremental indexing use the latest original code' do
    script = scripts(:one)
    original_code = ScriptCode.create!(code: 'latest original code')
    rewritten_code = ScriptCode.create!(code: 'latest rewritten code')
    ScriptVersion.insert_all!([{
                                script_id: script.id,
                                version: '2',
                                script_code_id: original_code.id,
                                rewritten_script_code_id: rewritten_code.id,
                              }])

    Dir.mktmpdir do |dir|
      File.write(File.join(dir, '999999999'), 'stale')
      stub_const(ScriptCodeSearch, :BASE_PATH, dir) do
        ScriptCodeSearch.index_all

        assert_equal original_code.code, File.read(File.join(dir, script.id.to_s))
        assert_equal script_codes(:four).code, File.read(File.join(dir, scripts(:with_namespace).id.to_s))
        assert_not File.exist?(File.join(dir, '999999999'))

        assert_equal [script.id], ScriptCodeSearch.search('latest original code', limit_to_ids: [script.id])
        assert_empty ScriptCodeSearch.search('latest rewritten code', limit_to_ids: [script.id])

        ScriptCodeSearch.index(script.id)
        assert_equal original_code.code, File.read(File.join(dir, script.id.to_s))
        assert_equal [script.id], ScriptCodeSearch.search('latest original code', limit_to_ids: [script.id])
        assert_empty ScriptCodeSearch.search('latest rewritten code', limit_to_ids: [script.id])
      end
    end
  end

  test 'search treats dash-prefixed queries as literal text' do
    Rails.logger.expects(:info).with(regexp_matches(/\Agrep code search status=completed elapsed=\d+\.\d{3}s\z/)).times(3)
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, '1'), 'contains --example')
      File.write(File.join(dir, '2'), 'other code')
      stub_const(ScriptCodeSearch, :BASE_PATH, dir) do
        assert_equal [1], ScriptCodeSearch.search('--example')
        assert_equal [1], ScriptCodeSearch.search('--example', limit_to_ids: [1, 2])
        assert_empty ScriptCodeSearch.search('missing')
        assert_empty ScriptCodeSearch.search('--example', limit_to_ids: [])
      end
    end
  end

  test 'search rejects multiline queries even when no ids are supplied' do
    Rails.logger.expects(:info).never
    ["first\nsecond", "first\rsecond", "first\r\nsecond"].each do |query|
      assert_raises(ArgumentError) { ScriptCodeSearch.search(query, limit_to_ids: []) }
    end
  end

  test 'search reports grep errors even when some files match' do
    Rails.logger.expects(:info).with(regexp_matches(/\Agrep code search status=failed elapsed=\d+\.\d{3}s\z/))
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, '1'), 'matching code')
      stub_const(ScriptCodeSearch, :BASE_PATH, dir) do
        error = assert_raises(RuntimeError) { ScriptCodeSearch.search('matching', limit_to_ids: [1, 2]) }
        assert_includes error.message, 'Code search failed'
        assert_includes error.message, File.join(dir, '2')
      end
    end
  end
end
