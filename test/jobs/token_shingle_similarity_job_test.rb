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

  test 'stores similarities at and above 25 percent but not below' do
    script = scripts(:one)
    at_threshold = scripts(:two)
    above_threshold = scripts(:three)
    below_threshold = scripts(:script_with_generated_version)
    {
      script => [1, 2],
      at_threshold => [1, 3, 4],
      above_threshold => [1, 2, 3, 4, 5],
      below_threshold => [1, 5, 6, 7, 8],
    }.each do |candidate, hashes|
      CodeSimilarityFingerprint.store_fingerprint!(candidate.id, { fingerprint: hashes.pack('Q>*'), token_count: 100 })
    end

    TokenShingleSimilarityJob.perform_now(script.id)

    [at_threshold, above_threshold].zip([0.25, 0.4]).each do |other_script, score|
      ids = [script.id, other_script.id].sort
      assert_in_delta score, TokenShingleSimilarity.find_by!(script_id: ids.first, other_script_id: ids.last).similarity.to_f
    end
    ids = [script.id, below_threshold.id].sort
    assert_not TokenShingleSimilarity.exists?(script_id: ids.first, other_script_id: ids.last)
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

  test 'previously deleted check is enqueued only for recent scripts with a single version' do
    script = scripts(:one)
    other_script = scripts(:two)
    fingerprint = TokenShingleSimilarityScorer.build_fingerprint('function run(){return 1;}')
    [script, other_script].each { |candidate| CodeSimilarityFingerprint.store_fingerprint!(candidate.id, fingerprint) }
    ScriptVersion.where(script_id: script.id).where.not(id: script.script_versions.first.id).delete_all

    script.update_columns(created_at: 30.minutes.ago)
    assert_enqueued_with(job: ScriptPreviouslyDeletedCheckJob, args: [script.id]) do
      TokenShingleSimilarityJob.perform_now(script.id)
    end

    clear_enqueued_jobs
    script.update_columns(created_at: 2.hours.ago)
    assert_no_enqueued_jobs(only: ScriptPreviouslyDeletedCheckJob) do
      TokenShingleSimilarityJob.perform_now(script.id)
    end

    script.update_columns(created_at: 30.minutes.ago)
    script.script_versions.first.dup.save!(validate: false)
    assert_no_enqueued_jobs(only: ScriptPreviouslyDeletedCheckJob) do
      TokenShingleSimilarityJob.perform_now(script.id)
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
