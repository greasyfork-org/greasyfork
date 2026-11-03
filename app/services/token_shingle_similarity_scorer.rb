require 'digest'
require 'json'
require 'open3'

class TokenShingleSimilarityScorer
  SHINGLE_SIZE = 5
  FINGERPRINT_SIZE = 256
  # Punctuation-only tokens are excluded from shingles so that each shingle is mostly meaningful code.
  STRUCTURAL_TOKEN_PATTERN = /\A[{}()\[\];,.]+\z/
  HASH_BYTES = 8
  FINGERPRINT_BYTES = FINGERPRINT_SIZE * HASH_BYTES
  DATABASE_BATCH_SIZE = 1_000
  MIN_SHARED_HASH_COUNT = 1
  SOURCE_LOCATION_CONTEXT_LINES = 2
  MAX_OCCURRENCE_PAIRS_PER_HASH = 10
  MAX_SNIPPET_LINES = 100
  MAX_SNIPPET_BYTES = 10 * 1024
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

    shingle_tokens = shingle_tokens_for(tokens)
    return { fingerprint: ''.b, token_count: tokens.size, locations: {} } if shingle_tokens.empty?

    shingle_size = [SHINGLE_SIZE, shingle_tokens.size].min
    hashes = bottom_hashes_for_tokens(shingle_tokens, shingle_size)
    {
      fingerprint: hashes.pack('Q>*'),
      token_count: tokens.size,
      locations: locations_for_hashes(shingle_tokens, shingle_size, hashes),
    }
  end

  def self.shingle_tokens_for(tokens)
    tokens.grep_v(->(token) { STRUCTURAL_TOKEN_PATTERN.match?(token.fetch('value')) })
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

    regions = common_regions(code, other_code, script_fingerprint.locations, other_fingerprint.locations, shared_hashes)
    script_line_starts = line_starts_for(code)
    other_line_starts = line_starts_for(other_code)
    {
      similarity_count: shared_hashes.size,
      maximum_similarity_count: comparable_hash_count,
      matches: regions.map do |script_range, other_range|
        {
          script: [source_section(code, script_line_starts, script_range)],
          other_script: [source_section(other_code, other_line_starts, other_range)],
        }
      end,
    }
  end

  # Returns [script_byte_range, other_script_byte_range] pairs. Each shared shingle occurrence is expanded
  # in both directions while the surrounding tokens are identical, and regions that touch on both sides are merged.
  def self.common_regions(code, other_code, locations, other_locations, shared_hashes)
    tokens = tokenize_with_locations(code)
    other_tokens = tokenize_with_locations(other_code)
    first_token_by_start = tokens.each_with_index.to_h { |token, index| [token.fetch('start'), index] }
    last_token_by_end = tokens.each_with_index.to_h { |token, index| [token.fetch('end'), index] }
    other_first_token_by_start = other_tokens.each_with_index.to_h { |token, index| [token.fetch('start'), index] }
    other_last_token_by_end = other_tokens.each_with_index.to_h { |token, index| [token.fetch('end'), index] }

    regions = []
    unaligned_regions = []
    shared_hashes.each do |hash|
      ranges = locations.fetch(hash.to_s, [])
      other_ranges = other_locations.fetch(hash.to_s, [])
      ranges.product(other_ranges).first(MAX_OCCURRENCE_PAIRS_PER_HASH).each do |range, other_range|
        first = first_token_by_start[range.first]
        last = last_token_by_end[range.last]
        other_first = other_first_token_by_start[other_range.first]
        other_last = other_last_token_by_end[other_range.last]
        unless first && last && other_first && other_last
          # Stored ranges that do not line up with tokens cannot be expanded; show them as they are.
          unaligned_regions << [range, other_range]
          next
        end

        while first.positive? && other_first.positive? && tokens[first - 1].fetch('value') == other_tokens[other_first - 1].fetch('value')
          first -= 1
          other_first -= 1
        end
        while last + 1 < tokens.size && other_last + 1 < other_tokens.size &&
              tokens[last + 1].fetch('value') == other_tokens[other_last + 1].fetch('value')
          last += 1
          other_last += 1
        end
        regions << [first, last, other_first, other_last]
      end
    end

    expanded_regions = merge_regions(regions).map do |first, last, other_first, other_last|
      [
        [tokens[first].fetch('start'), tokens[last].fetch('end')],
        [other_tokens[other_first].fetch('start'), other_tokens[other_last].fetch('end')],
      ]
    end
    (expanded_regions + unaligned_regions.uniq).sort
  end

  def self.merge_regions(regions)
    merged = []
    regions.sort.each do |region|
      region = region.dup
      loop do
        touching = merged.find { |other| regions_touch?(region, other) }
        break unless touching

        merged.delete(touching)
        region = [
          [region[0], touching[0]].min, [region[1], touching[1]].max,
          [region[2], touching[2]].min, [region[3], touching[3]].max
        ]
      end
      merged << region
    end
    merged.sort
  end

  def self.regions_touch?(region, other)
    region[0] <= other[1] + 1 && other[0] <= region[1] + 1 &&
      region[2] <= other[3] + 1 && other[2] <= region[3] + 1
  end

  def self.line_starts_for(code)
    line_starts = [0]
    code.b.to_enum(:scan, /\n/n).each { line_starts << Regexp.last_match.end(0) }
    line_starts
  end

  def self.source_section(code, line_starts, range)
    first_line = line_number_for_offset(line_starts, range.first)
    last_line = line_number_for_offset(line_starts, range.last)
    start_line = [first_line - SOURCE_LOCATION_CONTEXT_LINES, 0].max
    end_line = [last_line + SOURCE_LOCATION_CONTEXT_LINES, line_starts.size - 1].min
    source_start = line_starts.fetch(start_line)
    source_end = line_starts[end_line + 1] || code.bytesize
    capped_end = capped_snippet_end(code, line_starts, start_line, source_start, source_end)
    {
      source_range: [source_start, capped_end],
      highlight: range,
      first_line_number: start_line + 1,
      omitted_lines: code.byteslice(capped_end, source_end - capped_end).to_s.lines.size,
      omitted_bytes: source_end - capped_end,
    }
  end

  # Limits a snippet to MAX_SNIPPET_LINES lines and MAX_SNIPPET_BYTES bytes, cutting at a line boundary if possible.
  def self.capped_snippet_end(code, line_starts, start_line, source_start, source_end)
    capped_end = source_end
    line_limit_start = line_starts[start_line + MAX_SNIPPET_LINES]
    capped_end = [capped_end, line_limit_start].min if line_limit_start

    byte_limit = source_start + MAX_SNIPPET_BYTES
    if capped_end > byte_limit
      capped_end = line_starts.select { |line_start| line_start > source_start && line_start <= byte_limit }.max || byte_limit
      # Do not cut in the middle of a multibyte character.
      capped_end -= 1 while capped_end > source_start && (code.getbyte(capped_end) & 0xC0) == 0x80
    end
    capped_end
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
