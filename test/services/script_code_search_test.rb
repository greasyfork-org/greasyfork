require 'test_helper'
require 'tmpdir'

class ScriptCodeSearchTest < ActiveSupport::TestCase
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
