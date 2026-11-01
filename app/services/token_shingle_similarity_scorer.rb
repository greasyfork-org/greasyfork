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
  SOURCE_LOCATION_CONTEXT_LINES = 2
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
    tokens = tokenize_with_locations(code)
    return { fingerprint: ''.b, token_count: 0, locations: {} } if tokens.empty?

    shingle_size = [SHINGLE_SIZE, tokens.size].min
    hashes = bottom_hashes_for_tokens(tokens, shingle_size)
    { fingerprint: hashes.pack('Q>*'), token_count: tokens.size, locations: locations_for_hashes(tokens, shingle_size, hashes) }
  end

  def self.bottom_hashes_for_tokens(tokens, shingle_size)
    hashes = []
    selected_hashes = {}
    tokens.each_cons(shingle_size) do |shingle|
      hash = hash_for_tokens(shingle)
      next if selected_hashes.key?(hash)

      if hashes.size < FINGERPRINT_SIZE
        hashes << hash
        selected_hashes[hash] = true
        hashes.sort!
      elsif hash < hashes.last
        selected_hashes.delete(hashes.last)
        hashes[-1] = hash
        selected_hashes[hash] = true
        hashes.sort!
      end
    end
    hashes
  end

  def self.locations_for_hashes(tokens, shingle_size, hashes)
    selected_hashes = hashes.index_with(&:to_s)
    locations = selected_hashes.values.index_with { [] }
    tokens.each_cons(shingle_size) do |shingle|
      hash = selected_hashes[hash_for_tokens(shingle)]
      next unless hash

      range = [shingle.first.fetch('start'), shingle.last.fetch('end')]
      ranges = locations.fetch(hash)
      if ranges.any? && range.first <= ranges.last.last
        ranges.last[1] = [ranges.last.last, range.last].max
      else
        ranges << range
      end
    end
    locations
  end

  def self.hash_for_tokens(tokens)
    digest = Digest::SHA256.new
    tokens.each do |token|
      value = token.fetch('value')
      digest.update([value.bytesize].pack('N'))
      digest.update(value)
    end
    digest.digest.unpack1('Q>')
  end

  def self.common_source_locations_for(script, other_script, script_version_id:, other_script_version_id:, code:, other_code:)
    fingerprints = CodeSimilarityFingerprint.where(script_id: [script.id, other_script.id]).index_by(&:script_id)
    script_fingerprint = fingerprints[script.id]
    other_fingerprint = fingerprints[other_script.id]
    return unless source_locations_available?(script_fingerprint, script_version_id) &&
                  source_locations_available?(other_fingerprint, other_script_version_id)

    script_hashes = script_fingerprint.fingerprint.unpack('Q>*')
    other_hashes = other_fingerprint.fingerprint.unpack('Q>*')
    threshold_candidates = []
    threshold_candidates << script_hashes.last if script_hashes.size == FINGERPRINT_SIZE
    threshold_candidates << other_hashes.last if other_hashes.size == FINGERPRINT_SIZE
    threshold = threshold_candidates.min
    shared_hashes = script_hashes & other_hashes
    shared_hashes.select! { |hash| hash <= threshold } if threshold
    comparable_hash_count = if threshold
                              [script_hashes.count { |hash| hash <= threshold },
                               other_hashes.count { |hash| hash <= threshold }].min
                            else
                              [script_hashes.size, other_hashes.size].min
                            end

    script_sections = source_sections(code, script_fingerprint.locations, shared_hashes)
    other_script_sections = source_sections(other_code, other_fingerprint.locations, shared_hashes)
    {
      similarity_count: shared_hashes.size,
      maximum_similarity_count: comparable_hash_count,
      matches: shared_hashes.map do |hash|
        {
          script: script_sections.fetch(hash),
          other_script: other_script_sections.fetch(hash),
        }
      end,
    }
  end

  def self.source_sections(code, locations, shared_hashes)
    line_starts = [0]
    code.b.to_enum(:scan, /\n/n).each { line_starts << Regexp.last_match.end(0) }
    shared_hashes.to_h do |hash|
      sections = locations.fetch(hash.to_s, []).map do |range|
        first_line = line_number_for_offset(line_starts, range.first)
        last_line = line_number_for_offset(line_starts, range.last)
        start_line = [first_line - SOURCE_LOCATION_CONTEXT_LINES, 0].max
        end_line = [last_line + SOURCE_LOCATION_CONTEXT_LINES, line_starts.size - 1].min
        {
          source_range: [line_starts.fetch(start_line), line_starts[end_line + 1] || code.bytesize],
          highlight: range,
          first_line_number: start_line + 1,
        }
      end
      [hash, sections]
    end
  end

  def self.line_number_for_offset(line_starts, offset)
    (line_starts.bsearch_index { |line_start| line_start > offset } || line_starts.size) - 1
  end

  def self.source_locations_available?(fingerprint, version_id)
    fingerprint&.locations.present? && fingerprint.source_version_id == version_id
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
    tokenize_with_locations(code).map { |token| token.fetch('value') }
  end

  def self.tokenize_with_locations(code)
    stdout, stderr, status = Open3.capture3(
      'node',
      Rails.root.join('script/js_tokens_tokenize.mjs').to_s,
      stdin_data: code
    )
    raise "js-tokens tokenizer failed: #{stderr}" unless status.success?

    JSON.parse(stdout)
  end
end
