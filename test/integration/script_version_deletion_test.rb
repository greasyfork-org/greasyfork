require 'test_helper'

class ScriptVersionDeletionTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'deleting the latest version refreshes code processing and similarities' do
    script = scripts(:one)
    latest_version = add_newest_version_with_changed_code(script)
    sign_in users(:mod)

    CleanedCodeJob.expects(:perform_later).with { |job_script| job_script.id == script.id }
    CodeSimilarityFingerprintJob.expects(:perform_later).with { |job_script| job_script.id == script.id }
    token = delete_confirmation_token(script, latest_version)

    post script_script_version_do_delete_path(script_id: script.id, script_version_id: latest_version.id, locale: :en),
         params: { reason: 'Testing version deletion', authenticity_token: token }

    assert_response :redirect
  end

  test 'deleting a non-latest version does not refresh code processing or similarities' do
    script = scripts(:one)
    older_version = script.newest_saved_script_version
    add_newest_version_with_changed_code(script)
    sign_in users(:mod)

    CleanedCodeJob.expects(:perform_later).never
    CodeSimilarityFingerprintJob.expects(:perform_later).never
    token = delete_confirmation_token(script, older_version)

    post script_script_version_do_delete_path(script_id: script.id, script_version_id: older_version.id, locale: :en),
         params: { reason: 'Testing version deletion', authenticity_token: token }

    assert_response :redirect
  end

  private

  def delete_confirmation_token(script, version)
    get script_script_version_delete_path(script_id: script.id, script_version_id: version.id, locale: :en)
    response.parsed_body.at_css('input[name="authenticity_token"]')['value']
  end

  def add_newest_version_with_changed_code(script)
    previous_version = script.newest_saved_script_version
    latest_version = previous_version.dup
    latest_version.version = '2'
    latest_version.code = "#{previous_version.code}\nfoo();"
    latest_version.rewritten_code = "#{previous_version.rewritten_code}\nfoo();"
    script.apply_from_script_version(latest_version)
    latest_version.save!(validate: false)
    script.save!
    latest_version
  end
end
