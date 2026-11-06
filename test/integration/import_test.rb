require 'test_helper'
require 'script_importer/test_importer'

class ImportIntegrationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  SCRIPT_CODE = <<~JS.freeze
    // ==UserScript==
    // @name A Test!
    // @description Unit test.
    // @version 1.1
    // @namespace http://greasyfork.local/users/1
    // @include *
    // ==/UserScript==
    let foo = 'bar'
  JS

  setup do
    @user = users(:one)
    sign_in @user
  end

  test 'scripts imported on Sleazy Fork are self-reported as adult' do
    host! 'sleazyfork.local'
    ScriptImporter::TestImporter.stubs(:download).returns(SCRIPT_CODE)

    import_urls('https://example.com/first', 'https://example.com/second')

    assert_response :success
    ['https://example.com/first', 'https://example.com/second'].each do |url|
      script = @user.scripts.find_by!(sync_identifier: url)
      assert script.sensitive?
      assert_equal @user, script.marked_adult_by_user
    end
  end

  test 'scripts imported on Greasy Fork are not automatically adult' do
    host! 'greasyfork.local'
    ScriptImporter::TestImporter.stubs(:download).returns(SCRIPT_CODE)

    import_urls('https://example.com/script')

    assert_response :success
    script = @user.scripts.find_by!(sync_identifier: 'https://example.com/script')
    assert_not script.sensitive?
    assert_nil script.marked_adult_by_user
  end

  test 'scripts imported on Greasy Fork still become adult when targeting an adult site' do
    host! 'greasyfork.local'
    ScriptImporter::TestImporter.stubs(:download).returns(SCRIPT_CODE.sub('// @include *', '// @include http://pornonthecob.com'))

    import_urls('https://example.com/script')

    assert_response :success
    script = @user.scripts.find_by!(sync_identifier: 'https://example.com/script')
    assert script.sensitive?
    assert_nil script.marked_adult_by_user
  end

  test 'Sleazy Fork import marks scripts after a description is provided' do
    host! 'sleazyfork.local'
    ScriptImporter::TestImporter.stubs(:download).returns(SCRIPT_CODE.sub("// @description Unit test.\n", ''))
    url = 'https://example.com/script'

    import_urls(url)
    assert_response :success
    assert_not @user.scripts.exists?(sync_identifier: url)
    token = response.parsed_body.at_css('input[name="authenticity_token"]')['value']
    post import_add_path(locale: :en), params: { sync_ids: [url], "needsdescription-#{url}" => 'Unit test.', authenticity_token: token }

    assert_response :success
    script = @user.scripts.find_by!(sync_identifier: url)
    assert script.sensitive?
    assert_equal @user, script.marked_adult_by_user
  end

  test 'Sleazy Fork import does not change an existing script' do
    host! 'sleazyfork.local'
    script = scripts(:one)
    script.update!(sync_identifier: 'https://example.com/script', sensitive: false, marked_adult_by_user: nil)
    sign_in script.users.first
    ScriptImporter::TestImporter.stubs(:download).returns(SCRIPT_CODE)

    import_urls('https://example.com/script')

    assert_response :success
    assert_not script.reload.sensitive?
    assert_nil script.marked_adult_by_user
  end

  private

  def import_urls(*urls)
    get import_start_path(locale: :en)
    token = response.parsed_body.at_css('input[name="authenticity_token"]')['value']
    post import_add_path(locale: :en), params: { sync_urls: urls.join("\n"), authenticity_token: token }
  end
end
