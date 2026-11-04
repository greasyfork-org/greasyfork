require 'application_system_test_case'

class DerivativesTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

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

    assert_content 'Somewhat similar'
    assert_content 'A Test!'
    assert_link 'Diff'
  end

  test 'script comparison highlights common fingerprint source locations when available' do
    script = scripts(:one)
    other_script = scripts(:two)
    script_version = script.newest_saved_script_version
    other_script_version = other_script.newest_saved_script_version
    shared_code = 'function shared(){return 42;}'
    shared_fingerprint = TokenShingleSimilarityScorer.build_fingerprint(shared_code)
    shared_hash = shared_fingerprint.fetch(:fingerprint).unpack1('Q>')
    [script, other_script].zip([script_version, other_script_version]).each do |candidate, version|
      source = candidate.current_code
      fingerprint = {
        fingerprint: [shared_hash].pack('Q>*'),
        token_count: shared_fingerprint.fetch(:token_count),
        locations: { shared_hash.to_s => [[0, [source.bytesize, 5].min]] },
        source_version_id: version.id,
      }
      CodeSimilarityFingerprint.store_fingerprint!(candidate.id, fingerprint)
    end

    login_as(script.users.first, scope: :user)
    visit derivatives_script_url(script, locale: :en, compare: other_script.id, view: 'snippets')

    assert_selector '.common-source-comparison'
    assert_text 'We found 1 matches in a sample of 1 code snippets.'
    assert_selector 'mark.common-source-location', minimum: 2
    assert_selector '.common-source-line-number'
    assert_selector ".common-source-comparison a[href='#{script_path(other_script, locale: :en)}']"
    assert_selector ".common-source-comparison a[href='#{script_path(script, locale: :en)}']"
    other_script.users.each do |author|
      assert_selector '.common-source-match h5 a', text: author.name
    end
  end
end
