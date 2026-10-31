require 'test_helper'

class TokenShingleSimilarityJobTest < ActiveJob::TestCase
  test 'stores qualifying token-shingle similarities as canonical script pairs' do
    script = scripts(:one)
    other_script = scripts(:two)
    fingerprint = TokenShingleSimilarityScorer.build_fingerprint('function run(){return 1;}')
    [script, other_script].each do |candidate|
      CodeSimilarityFingerprint.store_fingerprint!(candidate.id, fingerprint)
    end

    TokenShingleSimilarityJob.perform_now(script.id)

    similarity = TokenShingleSimilarity.find_by!(script_id: script.id, other_script_id: other_script.id)
    assert_in_delta 0.999, similarity.similarity.to_f
    assert_not_nil similarity.checked_at
  end

  test 'replaces stale similarities when a script is rechecked' do
    script = scripts(:one)
    other_script = scripts(:two)
    stale_script = scripts(:three)
    fingerprint = TokenShingleSimilarityScorer.build_fingerprint('function run(){return 1;}')
    [script, other_script].each do |candidate|
      CodeSimilarityFingerprint.store_fingerprint!(candidate.id, fingerprint)
    end
    TokenShingleSimilarity.create!(
      script:,
      other_script: stale_script,
      similarity: 0.9,
      checked_at: Time.current
    )

    TokenShingleSimilarityJob.perform_now(script.id)

    assert TokenShingleSimilarity.exists?(script_id: script.id, other_script_id: other_script.id)
    assert_not TokenShingleSimilarity.exists?(script_id: script.id, other_script_id: stale_script.id)
  end

  test 'fingerprint job enqueues similarity computation after storing the fingerprint' do
    script = scripts(:one)

    assert_enqueued_with(job: TokenShingleSimilarityJob, args: [script.id]) do
      CodeSimilarityFingerprintJob.perform_now(script)
    end
  end

  test 'higher-ID mode preserves results owned by lower-ID scripts' do
    lower_script = scripts(:one)
    script = scripts(:two)
    higher_script = scripts(:three)
    fingerprint = TokenShingleSimilarityScorer.build_fingerprint('function run(){return 1;}')
    [lower_script, script, higher_script].each do |candidate|
      CodeSimilarityFingerprint.store_fingerprint!(candidate.id, fingerprint)
    end
    lower_owned_match = TokenShingleSimilarity.create!(
      script: lower_script,
      other_script: script,
      similarity: 0.9,
      checked_at: Time.current
    )

    TokenShingleSimilarityJob.perform_now(script.id, only_higher_ids: true)

    assert_predicate lower_owned_match, :persisted?
    assert TokenShingleSimilarity.exists?(script_id: script.id, other_script_id: higher_script.id)
    assert_equal 2, TokenShingleSimilarity.count
  end
end
