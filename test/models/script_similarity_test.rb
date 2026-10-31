require 'test_helper'

class ScriptSimilarityTest < ActiveSupport::TestCase
  test 'collects forward and inverse matches and keeps the highest score per script' do
    ScriptSimilarity.delete_all
    script = scripts(:one)
    forward_match = scripts(:two)
    inverse_match = scripts(:three)
    ScriptSimilarity.create!(script:, other_script: forward_match, similarity: 0.8, checked_at: Time.current)
    ScriptSimilarity.create!(script: forward_match, other_script: script, similarity: 0.9, checked_at: Time.current)
    ScriptSimilarity.create!(script: inverse_match, other_script: script, similarity: 0.85, checked_at: Time.current)
    ScriptSimilarity.create!(script:, other_script: scripts(:script_with_generated_version), similarity: 0.74, checked_at: Time.current)

    similarities = ScriptSimilarity.other_scripts_and_similarities_for(script, min_similarity: 0.75)

    assert_equal [
      [forward_match, 0.9],
      [inverse_match, 0.85],
    ], similarities
  end

  test 'does not query inverse matches when there are no forward matches' do
    ScriptSimilarity.delete_all
    script = scripts(:one)
    inverse_match = scripts(:two)
    ScriptSimilarity.create!(script: inverse_match, other_script: script, similarity: 0.9, checked_at: Time.current)

    similarities = ScriptSimilarity.other_scripts_and_similarities_for(script, min_similarity: 0.75)

    assert_empty similarities
  end
end
