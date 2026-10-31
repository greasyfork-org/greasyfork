require 'test_helper'

class TokenShingleSimilarityScorerTest < ActiveSupport::TestCase
  test 'fingerprint ignores formatting and comments' do
    base = 'function run(){return "text";}'
    formatted = "// comment\nfunction run () {\n  return \"text\";\n}"

    base_fingerprint = TokenShingleSimilarityScorer.build_fingerprint(base)
    formatted_fingerprint = TokenShingleSimilarityScorer.build_fingerprint(formatted)

    assert_equal base_fingerprint, formatted_fingerprint
    assert_in_delta 0.999, score(base_fingerprint, formatted_fingerprint)
  end

  test 'fingerprint comparison is symmetric' do
    base = TokenShingleSimilarityScorer.build_fingerprint('function first(){return 1;} function second(){return 2;}')
    other = TokenShingleSimilarityScorer.build_fingerprint('function first(){return 1;} function third(){return 3;}')

    assert_equal score(base, other), score(other, base)
  end

  test 'fingerprint supports non-ASCII source text' do
    fingerprint = TokenShingleSimilarityScorer.build_fingerprint('const greeting = "你好";')

    assert_operator fingerprint.fetch(:token_count), :>, 0
    assert_operator fingerprint.fetch(:fingerprint).bytesize, :>, 0
    assert_operator fingerprint.fetch(:fingerprint).bytesize, :<=, TokenShingleSimilarityScorer::FINGERPRINT_BYTES
  end

  test 'tokenization includes template expressions and recognizes regular expressions' do
    tokens = TokenShingleSimilarityScorer.tokenize('const value = `text ${name + 1}`; const pattern = /a+/g;')

    assert_includes tokens, 'name'
    assert_includes tokens, '+'
    assert_includes tokens, '1'
    assert_includes tokens, '/a+/g'
  end

  test 'fingerprints find shared code after more than 32 KB of different code' do
    shared_code = declarations('common')
    base = "#{shared_code}#{declarations('left')}function shared(){return \"shared\";}"
    other = "#{shared_code}#{declarations('right')}function shared(){return \"shared\";}"

    assert_operator base.bytesize, :>, 32_505
    base_fingerprint = TokenShingleSimilarityScorer.build_fingerprint(base)
    other_fingerprint = TokenShingleSimilarityScorer.build_fingerprint(other)
    assert_operator base_fingerprint.fetch(:fingerprint).bytesize, :<=, TokenShingleSimilarityScorer::FINGERPRINT_BYTES
    assert_operator score(base_fingerprint, other_fingerprint), :>, 0.0
  end

  test 'fingerprint job stores the raw fingerprint and searchable hashes' do
    script = scripts(:one)
    CodeSimilarityFingerprintJob.delete_for_script_id(script.id)

    CodeSimilarityFingerprintJob.perform_now(script)

    fingerprint = CodeSimilarityFingerprint.find_by!(script_id: script.id)
    raw = TokenShingleSimilarityScorer.build_fingerprint(script.current_code)
    assert_equal raw, { fingerprint: fingerprint.fingerprint, token_count: fingerprint.token_count }
    assert_equal raw.fetch(:fingerprint).bytesize / TokenShingleSimilarityScorer::HASH_BYTES,
                 CodeSimilarityFingerprintHash.where(script_id: script.id).count
  end

  test 'fingerprint job does not depend on cleaned code processing' do
    script = scripts(:one)
    JsCleanup.stubs(:cleanup).raises(JsCleanup::UncleanableException)

    CodeSimilarityFingerprintJob.perform_now(script)

    fingerprint = CodeSimilarityFingerprint.find_by!(script_id: script.id)
    raw = TokenShingleSimilarityScorer.build_fingerprint(script.current_code)
    assert_equal raw, { fingerprint: fingerprint.fingerprint, token_count: fingerprint.token_count }
  end

  test 'fingerprint job removes fingerprints for non-JavaScript scripts' do
    script = scripts(:one)
    other_script = scripts(:two)
    fingerprint = TokenShingleSimilarityScorer.build_fingerprint(script.current_code)
    CodeSimilarityFingerprint.store_fingerprint!(script.id, fingerprint)
    TokenShingleSimilarity.create!(
      script:,
      other_script:,
      similarity: 0.9,
      checked_at: Time.current
    )
    script.stubs(:js?).returns(false)

    CodeSimilarityFingerprintJob.perform_now(script)

    assert_not CodeSimilarityFingerprint.exists?(script_id: script.id)
    assert_not CodeSimilarityFingerprintHash.exists?(script_id: script.id)
    assert_not TokenShingleSimilarity.exists?(script_id: script.id, other_script_id: other_script.id)
  end

  test 'similarities can be fetched from stored fingerprints' do
    base_script = scripts(:one)
    other_script = scripts(:two)
    fingerprint = TokenShingleSimilarityScorer.build_fingerprint('function run(){return 1;}')
    [base_script, other_script].each do |script|
      CodeSimilarityFingerprint.store_fingerprint!(script.id, fingerprint)
    end

    similarities = TokenShingleSimilarityScorer.get_similarities(base_script)

    assert_equal [other_script.id], similarities.keys
    assert_operator similarities.fetch(other_script.id), :>=, 0.0
    assert_operator similarities.fetch(other_script.id), :<=, 0.999
  end

  test 'similarity between scripts returns scores below the display threshold' do
    base_script = scripts(:one)
    other_script = scripts(:two)
    base_fingerprint = { fingerprint: [1, 2, 3].pack('Q>*'), token_count: 100 }
    other_fingerprint = { fingerprint: [1, 4, 5].pack('Q>*'), token_count: 100 }
    TokenShingleSimilarityScorer.stubs(:fingerprint_for_script).with(base_script).returns(base_fingerprint)
    TokenShingleSimilarityScorer.stubs(:fingerprint_for_script).with(other_script).returns(other_fingerprint)

    similarity = TokenShingleSimilarityScorer.similarity_between(base_script, other_script)

    assert_in_delta 0.2, similarity
    assert_operator similarity, :<, TokenShingleSimilarityScorer::MIN_DISPLAYED_SIMILARITY
  end

  test 'similarity between scripts returns one for identical source code' do
    base_script = scripts(:one)
    other_script = scripts(:two)
    identical_code = 'function run(){return 1;}'
    base_script.stubs(:current_code).returns(identical_code)
    other_script.stubs(:current_code).returns(identical_code)

    assert_in_delta 1.0, TokenShingleSimilarityScorer.similarity_between(base_script, other_script)
  end

  test 'similarities only include candidates sharing a stored hash' do
    base_script = scripts(:one)
    matching_script = scripts(:two)
    different_script = scripts(:three)
    base_code = 'alpha bravo charlie delta echo foxtrot golf hotel india juliet'
    different_code = 'orange pear peach plum melon berry grape lemon lime apple'

    [base_script, matching_script, different_script].each { |script| CodeSimilarityFingerprint.where(script_id: script.id).delete_all }
    base_fingerprint = TokenShingleSimilarityScorer.build_fingerprint(base_code)
    CodeSimilarityFingerprint.store_fingerprint!(base_script.id, base_fingerprint)
    CodeSimilarityFingerprint.store_fingerprint!(matching_script.id, base_fingerprint)
    CodeSimilarityFingerprint.store_fingerprint!(different_script.id, TokenShingleSimilarityScorer.build_fingerprint(different_code))

    similarities = TokenShingleSimilarityScorer.get_similarities(base_script)

    assert_equal [matching_script.id], similarities.keys
  end

  test 'similarities exclude candidates whose token-count ratio cannot reach the display threshold' do
    base_script = scripts(:one)
    below_lower_bound = scripts(:two)
    at_lower_bound = scripts(:three)
    at_upper_bound = scripts(:script_with_generated_version)
    above_upper_bound = scripts(:script_with_explicit_version)
    fingerprint = TokenShingleSimilarityScorer.build_fingerprint('function run(){return 1;}')
    {
      base_script => 100,
      below_lower_bound => 49,
      at_lower_bound => 50,
      at_upper_bound => 200,
      above_upper_bound => 201,
    }.each do |script, token_count|
      CodeSimilarityFingerprint.store_fingerprint!(
        script.id,
        fingerprint.merge(token_count:)
      )
    end

    similarities = TokenShingleSimilarityScorer.get_similarities(base_script)

    assert_equal [at_lower_bound.id, at_upper_bound.id].sort, similarities.keys.sort
    assert_operator similarities.fetch(at_lower_bound.id), :>=, TokenShingleSimilarityScorer::MIN_DISPLAYED_SIMILARITY
    assert_operator similarities.fetch(at_upper_bound.id), :>=, TokenShingleSimilarityScorer::MIN_DISPLAYED_SIMILARITY
  end

  test 'similarities search fingerprinted scripts and exclude the base script' do
    base_script = scripts(:one)
    javascript_script = scripts(:two)
    css_script = scripts(:three)
    fingerprint = TokenShingleSimilarityScorer.build_fingerprint('function run(){return 1;}')
    [base_script, javascript_script, css_script].each do |script|
      CodeSimilarityFingerprint.store_fingerprint!(script.id, fingerprint)
    end
    css_script.update_column(:language, 'css')

    similarities = TokenShingleSimilarityScorer.get_similarities(base_script)

    assert_equal [javascript_script.id, css_script.id].sort, similarities.keys.sort
    assert_not_includes similarities.keys, base_script.id
  end

  test 'similarities can restrict candidates to higher script IDs' do
    lower_script = scripts(:one)
    base_script = scripts(:two)
    higher_script = scripts(:three)
    fingerprint = TokenShingleSimilarityScorer.build_fingerprint('function run(){return 1;}')
    [lower_script, base_script, higher_script].each do |script|
      CodeSimilarityFingerprint.store_fingerprint!(script.id, fingerprint)
    end

    similarities = TokenShingleSimilarityScorer.get_similarities(base_script, only_higher_ids: true)

    assert_equal [higher_script.id], similarities.keys
  end

  private

  def score(base, other)
    TokenShingleSimilarityScorer.score_for_fingerprints(
      base.fetch(:fingerprint),
      base.fetch(:token_count),
      other.fetch(:fingerprint),
      other.fetch(:token_count)
    )
  end

  def declarations(prefix)
    (0...6_000).map { |index| "var #{prefix}#{index}=#{index};" }.join
  end
end
