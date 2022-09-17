require 'application_system_test_case'

module Scripts
  class SubresourceTest < ApplicationSystemTestCase
    test 'bad subresource' do
      script = Script.find(2)
      subresource = Subresource.create!(url: 'https://example.com/test.js', last_success_at: Time.zone.now)
      ScriptSubresourceUsage.create!(script:, subresource:, algorithm: 'sha256', encoding: 'hex', integrity_hash: 'a')
      subresource.subresource_integrity_hashes.create!(algorithm: 'sha256', encoding: 'hex', integrity_hash: 'b')
      login_as(script.users.first)
      visit script_path(script, locale: :en)
      assert_content 'This script uses an incorrect subresource integrity hash'
      visit user_path(script.users.first, locale: :en)
      assert_content 'You have a script with an incorrect subresource integrity hash'
    end

    test 'good subresource' do
      script = Script.find(2)
      subresource = Subresource.create!(url: 'https://example.com/test.js', last_success_at: Time.zone.now)
      ScriptSubresourceUsage.create!(script:, subresource:, algorithm: 'sha256', encoding: 'hex', integrity_hash: 'a')
      subresource.subresource_integrity_hashes.create!(algorithm: 'sha256', encoding: 'hex', integrity_hash: 'a')
      login_as(script.users.first)
      visit script_path(script, locale: :en)
      assert_no_content 'This script uses an incorrect subresource integrity hash'
      visit user_path(script.users.first, locale: :en)
      assert_no_content 'You have a script with an incorrect subresource integrity hash'
    end

    test 'no subresource' do
      script = Script.find(2)
      login_as(script.users.first)
      visit script_path(script, locale: :en)
      assert_no_content 'This script uses an incorrect subresource integrity hash'
      visit user_path(script.users.first, locale: :en)
      assert_no_content 'You have a script with an incorrect subresource integrity hash'
    end
  end
end
