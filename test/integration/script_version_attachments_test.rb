require 'test_helper'

class ScriptVersionAttachmentsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    users(:one).update!(otp_required_for_login: true)
  end

  test 'creating a script without an attachments parameter' do
    sign_in users(:one)
    get new_script_version_path(locale: :en)
    post script_versions_path(locale: :en), params: {
      authenticity_token: authenticity_token,
      script: { script_type: '1' },
      script_version: { code: script_codes(:one).code.sub('A Test!', 'Script without screenshots') },
    }

    assert_response :redirect
    assert_not Script.last.newest_saved_script_version.attachments.attached?
  end

  test 'updating a script without screenshots or an attachments parameter' do
    script = scripts(:one)
    sign_in script.users.first
    post_update(script, script_version: { code: updated_code(script) })

    assert_response :redirect
    assert_not script.reload.newest_saved_script_version.attachments.attached?
  end

  test 'rejecting an update that omits existing screenshots' do
    script = scripts(:one)
    previous_version = script.newest_saved_script_version
    attach_screenshot(previous_version, 'blacklogo16.png')
    sign_in script.users.first

    assert_no_difference -> { script.script_versions.count } do
      assert_raises(ActionController::BadRequest) do
        post_update(script, script_version: { code: updated_code(script) })
      end
    end
    assert_equal 1, previous_version.attachments.count
  end

  test 'rejecting malformed attachments' do
    sign_in users(:one)
    get new_script_version_path(locale: :en)
    token = authenticity_token

    ['not-an-array', { unexpected: 'value' }, ['valid-looking', { unexpected: 'value' }]].each do |attachments|
      assert_raises(ActionController::BadRequest) do
        post script_versions_path(locale: :en), params: {
          authenticity_token: token,
          script_version: { code: 'test', attachments: },
        }
      end
    end
  end

  test 'retaining, removing, and uploading screenshots on update' do
    script = scripts(:one)
    previous_version = script.newest_saved_script_version
    attach_screenshot(previous_version, 'blacklogo16.png')
    attach_screenshot(previous_version, 'blacklogo32.png')
    retained, removed = previous_version.attachments.to_a
    sign_in script.users.first

    upload = fixture_file_upload(Rails.public_path.join('images/blacklogo128.png'), 'image/png')
    post_update(script, script_version: { code: updated_code(script), attachments: ['', retained.signed_id, removed.signed_id, upload] },
                        "remove-attachment-#{removed.signed_id}" => '1')

    assert_response :redirect
    attachments = script.reload.newest_saved_script_version.attachments
    assert_includes attachments.map(&:blob_id), retained.blob_id
    assert_equal ['blacklogo128.png', 'blacklogo16.png'], attachments.map { |attachment| attachment.filename.to_s }.sort
    assert_equal 2, previous_version.attachments.count
  end

  test 'removing all screenshots on update' do
    script = scripts(:one)
    previous_version = script.newest_saved_script_version
    attach_screenshot(previous_version, 'blacklogo16.png')
    removed = previous_version.attachments.first
    sign_in script.users.first

    post_update(script, script_version: { code: updated_code(script), attachments: ['', removed.signed_id] },
                        "remove-attachment-#{removed.signed_id}" => '1')

    assert_response :redirect
    assert_not script.reload.newest_saved_script_version.attachments.attached?
    assert_equal 1, previous_version.attachments.count
  end

  private

  def authenticity_token
    form = response.parsed_body.at_css('textarea[name="script_version[code]"]').ancestors('form').first
    form.at_css('input[name="authenticity_token"]')['value']
  end

  def updated_code(script)
    script.newest_saved_script_version.code.sub('@version 1.1', '@version 1.2')
  end

  def attach_screenshot(version, filename)
    version.attachments.attach(io: Rails.public_path.join('images', filename).open, filename:, content_type: 'image/png')
  end

  def post_update(script, **params)
    get new_script_script_version_path(script_id: script.id, locale: :en)
    post script_script_versions_path(script_id: script, locale: :en),
         params: { authenticity_token: authenticity_token, script: { script_type: script.script_type_before_type_cast } }.merge(params)
  end
end
