require 'test_helper'

class CodeSimilarityFingerprintJobTest < ActiveJob::TestCase
  CODE = <<~JS.freeze
    // ==UserScript==
    // @name		Brand New Fingerprint Script
    // @description		Created from scratch.
    // @namespace		http://greasyfork.local/users/1
    // @version		1.0
    // @include		*
    // @license		MIT
    // ==/UserScript==
    function greet(name) { return 'Hello, ' + name + '!'; }
    document.title = greet('world');
  JS

  def create_new_script
    script_version = ScriptVersion.new(code: CODE, changelog: 'Initial version')
    script = Script.new(language: 'js', script_type: :public)
    script.authors.build(user: User.find(1))
    script_version.script = script
    script.script_versions << script_version
    script_version.do_lenient_saving
    script_version.calculate_all(nil)
    script.apply_from_script_version(script_version)
    assert script.valid?, script.errors.full_messages.to_sentence
    assert script_version.valid?, script_version.errors.full_messages.to_sentence
    script.save!
    script
  end

  test 'a brand new script is fingerprinted and queued for similarity' do
    script = nil
    assert_enqueued_with(job: CodeSimilarityFingerprintJob) { script = create_new_script }
    assert_nil CodeSimilarityFingerprint.find_by(script_id: script.id)

    perform_enqueued_jobs(only: CodeSimilarityFingerprintJob)

    fingerprint = CodeSimilarityFingerprint.find_by!(script_id: script.id)
    assert_equal script.newest_saved_script_version.id, fingerprint.source_version_id
    assert_operator fingerprint.token_count, :>, 0
    assert_operator fingerprint.fingerprint.bytesize, :>, 0
    assert_operator fingerprint.locations.size, :>, 0
    assert_enqueued_with(job: TokenShingleSimilarityJob, args: [script.id])
  end

  test 'a brand new script is found similar to an identical existing script' do
    existing_script = scripts(:one)
    fingerprint = TokenShingleSimilarityScorer.build_fingerprint(ScriptVersion.new(code: CODE).code)
    fingerprint[:source_version_id] = existing_script.newest_saved_script_version.id
    CodeSimilarityFingerprint.store_fingerprint!(existing_script.id, fingerprint)

    script = create_new_script
    perform_enqueued_jobs(only: CodeSimilarityFingerprintJob)
    perform_enqueued_jobs(only: TokenShingleSimilarityJob)

    similarity = TokenShingleSimilarity.find_by!(script_id: existing_script.id, other_script_id: script.id)
    assert_in_delta 0.999, similarity.similarity.to_f
  end
end
