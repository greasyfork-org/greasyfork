require 'application_system_test_case'

class DerivativesTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  test 'script derivatives' do
    script = Script.find(1)
    login_as(script.users.first, scope: :user)
    visit derivatives_script_url(script, locale: :en)
    click_on 'Recheck now'
    assert_content 'Similarity check will be completed in a few minutes.'
  end

  test 'script derivatives show precomputed token-shingle similarities' do
    script = scripts(:one)
    other_script = scripts(:two)
    TokenShingleSimilarity.create!(
      script:,
      other_script:,
      similarity: 0.6,
      checked_at: Time.current
    )
    login_as(script.users.first, scope: :user)

    visit derivatives_script_url(script, locale: :en)

    assert_content 'Token-shingle similarity'
    assert_no_content 'Similarity method comparison'
    assert_content 'Somewhat similar'
    assert_content 'A Test!'
    assert_link 'Diff'
  end

  test 'moderators can compare compression-only and token-shingle-only matches' do
    script = scripts(:one)
    compression_only_script = scripts(:two)
    token_only_script = scripts(:three)
    ScriptSimilarity.delete_all
    ScriptSimilarity.create!(
      script:,
      other_script: compression_only_script,
      similarity: 0.9,
      checked_at: Time.current
    )
    TokenShingleSimilarity.create!(
      script:,
      other_script: token_only_script,
      similarity: 0.6,
      checked_at: Time.current
    )
    login_as(users(:mod), scope: :user)

    visit derivatives_script_url(script, locale: :en)

    assert_content 'Similarity method comparison (moderators only)'
    assert_selector "#compression-only-matches li[data-script-id='#{compression_only_script.id}']", text: 'Moderately similar'
    assert_selector "#token-shingle-only-matches li[data-script-id='#{token_only_script.id}']", text: 'Somewhat similar'
  end
end
