require 'digest'
require 'json'
require 'open3'

class TokenShingleSimilarityScorer
  SHINGLE_SIZE = 5
  FINGERPRINT_SIZE = 256
  HASH_BYTES = 8
  FINGERPRINT_BYTES = FINGERPRINT_SIZE * HASH_BYTES
  DATABASE_BATCH_SIZE = 1_000
  MIN_SHARED_HASH_COUNT = 1
  MIN_DISPLAYED_SIMILARITY_NUMERATOR = 1
  MIN_DISPLAYED_SIMILARITY_DENOMINATOR = 2
  MIN_DISPLAYED_SIMILARITY = MIN_DISPLAYED_SIMILARITY_NUMERATOR.to_f / MIN_DISPLAYED_SIMILARITY_DENOMINATOR

  def self.similarity_between(base_script, other_script)
    base_code = base_script.current_code
    return 1.0 if base_code.present? && base_code == other_script.current_code

    base_fingerprint = fingerprint_for_script(base_script)
    other_fingerprint = fingerprint_for_script(other_script)

    score_for_fingerprints(
      base_fingerprint.fetch(:fingerprint),
      base_fingerprint.fetch(:token_count),
      other_fingerprint.fetch(:fingerprint),
      other_fingerprint.fetch(:token_count)
    )
  end

  def self.get_similarities(base_script, only_higher_ids: false)
    base_fingerprint = fingerprint_for_script(base_script)
    results = {}
    base_hashes = hashes_for_fingerprint(base_fingerprint.fetch(:fingerprint))
    base_token_count = base_fingerprint.fetch(:token_count)
    return results if base_hashes.empty? || base_token_count.zero?

    candidate_hashes = CodeSimilarityFingerprintHash
                       .where(fingerprint_hash: base_hashes)
                       .where.not(script_id: base_script.id)
    candidate_hashes = candidate_hashes.where('script_id > ?', base_script.id) if only_higher_ids

    candidate_script_ids = candidate_hashes
                           .group(:script_id)
                           .having('COUNT(*) >= ?', MIN_SHARED_HASH_COUNT)
                           .select(:script_id)

    fingerprints = CodeSimilarityFingerprint
                   .where(script_id: candidate_script_ids)
                   .where(
                     'token_count * ? >= ? AND token_count * ? <= ?',
                     MIN_DISPLAYED_SIMILARITY_DENOMINATOR,
                     base_token_count * MIN_DISPLAYED_SIMILARITY_NUMERATOR,
                     MIN_DISPLAYED_SIMILARITY_NUMERATOR,
                     base_token_count * MIN_DISPLAYED_SIMILARITY_DENOMINATOR
                   )

    fingerprints.in_batches(of: DATABASE_BATCH_SIZE) do |batch|
      batch.pluck(
        :script_id,
        :fingerprint,
        :token_count
      ).each do |script_id, fingerprint, token_count|
        next if fingerprint.nil? || token_count.nil?

        results[script_id] = score_for_fingerprints(
          base_fingerprint.fetch(:fingerprint),
          base_token_count,
          fingerprint,
          token_count
        )
      end
    end

    results
  end

  def self.hashes_for_fingerprint(fingerprint)
    (0...fingerprint.bytesize).step(HASH_BYTES).map { |offset| fingerprint.byteslice(offset, HASH_BYTES) }
  end

  def self.fingerprint_for_script(script)
    record = CodeSimilarityFingerprint.find_by(script_id: script.id)
    fingerprint = record&.fingerprint
    if fingerprint
      return {
        fingerprint:,
        token_count: record.token_count,
      }
    end

    build_fingerprint(script.current_code)
  end

  def self.build_fingerprint(code)
    tokens = tokenize(code)
    return { fingerprint: ''.b, token_count: 0 } if tokens.empty?

    shingle_size = [SHINGLE_SIZE, tokens.size].min
    shingles = tokens.each_cons(shingle_size).map do |shingle|
      digest = Digest::SHA256.new
      shingle.each do |token|
        digest.update([token.bytesize].pack('N'))
        digest.update(token)
      end
      digest.digest.unpack1('Q>')
    end.uniq.sort.first(FINGERPRINT_SIZE)

    { fingerprint: shingles.pack('Q>*'), token_count: tokens.size }
  end

  def self.score_for_fingerprints(base_fingerprint, base_token_count, other_fingerprint, other_token_count)
    return 0.0 if base_fingerprint.nil? || other_fingerprint.nil?
    return 0.0 if base_token_count.zero? || other_token_count.zero?

    base_hashes = base_fingerprint.unpack('Q>*')
    other_hashes = other_fingerprint.unpack('Q>*')
    return 0.0 if base_hashes.empty? || other_hashes.empty?

    threshold_candidates = []
    threshold_candidates << base_hashes.last if base_hashes.size == FINGERPRINT_SIZE
    threshold_candidates << other_hashes.last if other_hashes.size == FINGERPRINT_SIZE
    threshold = threshold_candidates.min
    if threshold
      # Membership is known for both fingerprints below the smaller bottom-k cutoff.
      base_hashes = base_hashes.take_while { |hash| hash <= threshold }
      other_hashes = other_hashes.take_while { |hash| hash <= threshold }
    end

    union_size = (base_hashes | other_hashes).size
    intersection_size = (base_hashes & other_hashes).size
    jaccard_similarity = intersection_size.to_f / union_size
    token_count_ratio = [base_token_count, other_token_count].min.to_f / [base_token_count, other_token_count].max

    [jaccard_similarity, token_count_ratio, 0.999].min
  end

  def self.tokenize(code)
    stdout, stderr, status = Open3.capture3(
      'node',
      Rails.root.join('script/js_tokens_tokenize.mjs').to_s,
      stdin_data: code
    )
    raise "js-tokens tokenizer failed: #{stderr}" unless status.success?

    JSON.parse(stdout)
  end
end
