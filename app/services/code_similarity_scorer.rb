require 'zlib'

class CodeSimilarityScorer
  def self.get_similarities(base_script, other_scripts)
    results = {}

    base_code = base_script.current_code
    base_length = base_code.size
    base_compressed_length = get_compressed_size(base_code)

    compressed_length_if_identical = get_compressed_size(base_code + base_code)

    # Create a map from script id to code id
    script_id_and_latest_version_id = ScriptVersion.where(script_id: other_scripts).group(:script_id).pluck(:script_id, 'MAX(id)')
    script_version_id_and_code_id = ScriptVersion.where(id: script_id_and_latest_version_id.map(&:last)).pluck(:id, :script_code_id).to_h
    script_id_and_code_id = script_id_and_latest_version_id.map { |script_id, script_version_id| [script_id, script_version_id_and_code_id[script_version_id]] }

    script_id_and_code_id.each_slice(100) do |slice|
      script_code_id_to_code = ScriptCode.where(id: slice.map(&:last)).pluck(:id, :code).to_h

      slice.each do |script_id, code_id|
        other_code = script_code_id_to_code[code_id]
        other_code_length = other_code.size
        other_compressed_length = get_compressed_size(other_code)

        combined_compressed_length = get_compressed_size(base_code + other_code)
        compressed_length_if_completely_different = base_compressed_length + other_compressed_length

        # How far between identical and completely different are we, normalized to 0..1.
        differentness = (combined_compressed_length - compressed_length_if_identical).to_f / compressed_length_if_completely_different
        # Put a ceiling in so very short scripts don't come up as very similar. If it's 50% of the length, then the 0.5 is the highest it can get.
        results[script_id] = [1.0 - differentness, other_code_length.to_f / base_length].min
      end
    end

    results
  end

  def self.get_compressed_size(s)
    Zlib::Deflate.deflate(s, Zlib::BEST_SPEED).size
  end
end