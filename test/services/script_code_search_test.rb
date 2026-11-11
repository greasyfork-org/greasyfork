require 'test_helper'
require 'tmpdir'

class ScriptCodeSearchTest < ActiveSupport::TestCase
  test 'index all writes the latest rewritten code and removes stale files' do
    script = scripts(:one)
    rewritten_code = ScriptCode.create!(code: 'latest rewritten code')
    ScriptVersion.insert_all!([{
                                script_id: script.id,
                                version: '2',
                                script_code_id: script_codes(:two).id,
                                rewritten_script_code_id: rewritten_code.id,
                              }])

    Dir.mktmpdir do |dir|
      File.write(File.join(dir, '999999999'), 'stale')
      stub_const(ScriptCodeSearch, :BASE_PATH, dir) do
        ScriptCodeSearch.index_all

        assert_equal rewritten_code.code, File.read(File.join(dir, script.id.to_s))
        assert_equal script_codes(:five).code, File.read(File.join(dir, scripts(:with_namespace).id.to_s))
        assert_not File.exist?(File.join(dir, '999999999'))
      end
    end
  end

  test 'search treats dash-prefixed queries as literal text' do
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
    ["first\nsecond", "first\rsecond", "first\r\nsecond"].each do |query|
      assert_raises(ArgumentError) { ScriptCodeSearch.search(query, limit_to_ids: []) }
    end
  end

  test 'search reports grep errors even when some files match' do
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
