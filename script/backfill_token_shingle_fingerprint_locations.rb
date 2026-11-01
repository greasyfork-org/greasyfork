require 'json'

checkpoint_path = Rails.root.join(ENV.fetch('CHECKPOINT_PATH', 'tmp/token_shingle_fingerprint_locations_backfill.json'))
pause_seconds = Float(ENV.fetch('PAUSE_SECONDS', '0.1'))
limit = ENV['LIMIT']&.then { |value| Integer(value, 10) }
start_after_id = ENV['START_AFTER_ID']&.then { |value| Integer(value, 10) }

raise 'PAUSE_SECONDS must not be negative' if pause_seconds.negative?
raise 'LIMIT must be positive' if limit && !limit.positive?
raise 'START_AFTER_ID must not be negative' if start_after_id&.negative?

if File.exist?(checkpoint_path)
  raise 'START_AFTER_ID cannot be combined with an existing checkpoint' if start_after_id

  checkpoint = JSON.parse(File.read(checkpoint_path))
  raise 'Invalid checkpoint order' unless checkpoint['order'] == 'ascending_locations'

  last_script_id = Integer(checkpoint.fetch('last_script_id'))
  processed_count = Integer(checkpoint.fetch('processed_count', 0))
  updated_count = Integer(checkpoint.fetch('updated_count', 0))
  skipped_count = Integer(checkpoint.fetch('skipped_count', 0))
else
  last_script_id = start_after_id || 0
  processed_count = 0
  updated_count = 0
  skipped_count = 0
end

scripts = Script.joins(:code_similarity_fingerprint)
                .where('scripts.id > ?', last_script_id)
                .order(:id)
scripts = scripts.limit(limit) if limit

puts "Starting after script ID #{last_script_id}; #{scripts.count} stored fingerprints in this run."
puts "Checkpoint: #{checkpoint_path}"

processed_this_run = 0
scripts.find_each do |script|
  version = script.newest_saved_script_version
  fingerprint_record = script.code_similarity_fingerprint

  if version.nil? || version.code.nil?
    skipped_count += 1
    puts "Skipping script #{script.id}: no saved source version."
  else
    rebuilt_fingerprint = TokenShingleSimilarityScorer.build_fingerprint(version.code)
    if rebuilt_fingerprint.fetch(:fingerprint) != fingerprint_record.fingerprint ||
       rebuilt_fingerprint.fetch(:token_count) != fingerprint_record.token_count
      skipped_count += 1
      puts "Skipping script #{script.id}: current source does not match the stored fingerprint."
    else
      fingerprint_record.update_columns(
        locations: rebuilt_fingerprint.fetch(:locations),
        source_version_id: version.id
      )
      updated_count += 1
    end
  end

  last_script_id = script.id
  processed_count += 1
  processed_this_run += 1
  checkpoint = {
    order: 'ascending_locations',
    last_script_id:,
    processed_count:,
    updated_count:,
    skipped_count:,
  }
  temporary_checkpoint_path = "#{checkpoint_path}.tmp"
  File.write(temporary_checkpoint_path, JSON.pretty_generate(checkpoint))
  File.rename(temporary_checkpoint_path, checkpoint_path)

  puts "Processed #{processed_count} fingerprints through script ID #{last_script_id}." if (processed_count % 100).zero?
  sleep(pause_seconds) if pause_seconds.positive?
end

puts "Location backfill complete: processed #{processed_this_run}; updated #{updated_count}; skipped #{skipped_count}."
