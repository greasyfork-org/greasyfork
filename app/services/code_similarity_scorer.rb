require 'zlib'

class CodeSimilarityScorer
  def self.get_similarities(base_script, other_scripts, tersed: false)
    results = {}

    base_code = tersed ? (base_script.cleaned_code&.code || base_script.current_code) : base_script.current_code
    base_length = base_code.size
    base_compressed_length = get_compressed_size(base_code)

    # The "look-behind" only works for 32KB. If the code is longer than that then two copies of it won't get fully
    # compressed. This also means we're unlikely to find very similar scripts.
    # https://en.wikipedia.org/wiki/DEFLATE#Duplicate_string_elimination
    #
    # 32505 is around 32KB - that seems like point things jump in size.
    # ((31.7.kilobytes.to_i)..(31.8.kilobytes.to_i)).each { |i| puts "#{i} #{get_compressed_size(SecureRandom.alphanumeric(i) * 2)}" }
    compressed_length_if_identical = if base_code.bytesize > 32_505
                                       base_compressed_length
                                     else
                                       get_compressed_size(base_code * 2)
                                     end

    if tersed
      # Avoid loading all CleanCodes as that will cause memory issues. Also avoid repeatedly passing huge amounts of IDs in SQL statements -
      # load the IDs then use in_groups_of.
      cleaned_code_ids = CleanedCode.where(script_id: other_scripts.pluck(:id)).pluck(:id)
      cleaned_code_ids.in_groups_of(100, false) do |cleaned_code_ids_group|
        # rubocop:disable Rails/FindEach
        CleanedCode.where(id: cleaned_code_ids_group).each do |cleaned_code|
          # rubocop:enable Rails/FindEach
          results[cleaned_code.script_id] = score_for_codes(base_code, cleaned_code.code, base_length:, base_compressed_length:, compressed_length_if_identical:)
        end
      end

      return results
    end

    # Create a map from script id to code id
    script_id_and_latest_version_id = ScriptVersion.where(script_id: other_scripts).group(:script_id).pluck(:script_id, 'MAX(id)')
    script_version_id_and_code_id = ScriptVersion.where(id: script_id_and_latest_version_id.map(&:last)).pluck(:id, :script_code_id).to_h
    script_id_and_code_id = script_id_and_latest_version_id.map { |script_id, script_version_id| [script_id, script_version_id_and_code_id[script_version_id]] }

    script_id_and_code_id.each_slice(100) do |slice|
      script_code_id_to_code = ScriptCode.where(id: slice.map(&:last)).pluck(:id, :code).to_h

      slice.each do |script_id, code_id|
        other_code = script_code_id_to_code[code_id]
        results[script_id] = score_for_codes(base_code, other_code, base_length:, base_compressed_length:, compressed_length_if_identical:)
      end
    end

    results
  end

  def self.score_for_codes(base_code, other_code, base_length:, base_compressed_length:, compressed_length_if_identical:)
    return 0.0 if other_code.nil?

    return 1.000 if base_code == other_code

    other_code_length = other_code.size

    # If the length is very different, assume not at all similar.
    return 0.0 unless ((base_length / 2)..(base_length * 2)).cover?(other_code_length)

    other_compressed_length = get_compressed_size(other_code)

    combined_compressed_length = get_compressed_size(base_code + other_code)
    compressed_length_if_completely_different = base_compressed_length + other_compressed_length

    # How far between identical and completely different are we, normalized to 0..1.
    differentness = (combined_compressed_length - compressed_length_if_identical).to_f / compressed_length_if_completely_different
    # Put a ceiling in so very short scripts (before or after compression) don't come up as very similar.
    # If it's 50% of the length, then the 0.5 is the highest it can get.
    # In addition, if they're not identical, max out at 0.999 (avoiding rounding up to 1.000).
    [1.0 - differentness, other_code_length.to_f / base_length, other_compressed_length.to_f / base_compressed_length, 0.999].min
  end

  def self.get_compressed_size(code)
    Zlib::Deflate.deflate(code, Zlib::BEST_SPEED).size
  end
end
