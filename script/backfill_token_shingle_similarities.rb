require 'json'

checkpoint_path = Rails.root.join(ENV.fetch('CHECKPOINT_PATH', 'tmp/token_shingle_similarity_backfill.json'))
pause_seconds = Float(ENV.fetch('PAUSE_SECONDS', '0.1'))
max_queue_size = Integer(ENV.fetch('MAX_SIDEKIQ_QUEUE_SIZE', '100'), 10)
queue_poll_seconds = Float(ENV.fetch('QUEUE_POLL_SECONDS', '30'))
limit = ENV['LIMIT']&.then { |value| Integer(value, 10) }
start_before_id = ENV['START_BEFORE_ID']&.then { |value| Integer(value, 10) }

raise 'PAUSE_SECONDS must not be negative' if pause_seconds.negative?
raise 'MAX_SIDEKIQ_QUEUE_SIZE must not be negative' if max_queue_size.negative?
raise 'QUEUE_POLL_SECONDS must be positive' unless queue_poll_seconds.positive?
raise 'LIMIT must be positive' if limit && !limit.positive?
raise 'START_BEFORE_ID must not be negative' if start_before_id&.negative?

if File.exist?(checkpoint_path)
  raise 'START_BEFORE_ID cannot be combined with an existing checkpoint' if start_before_id

  checkpoint = JSON.parse(File.read(checkpoint_path))
  raise 'Checkpoint was created for a different backfill order' unless checkpoint['order'] == 'descending'

  last_script_id = Integer(checkpoint.fetch('last_script_id'), 10)
  processed_count = Integer(checkpoint.fetch('processed_count', 0), 10)
  fingerprint_count = Integer(checkpoint.fetch('fingerprint_count', 0), 10)
else
  last_script_id = start_before_id || (Script.maximum(:id).to_i + 1)
  processed_count = 0
  fingerprint_count = 0
end

scripts = Script.where(language: 'js')
                .where('code_size > 0')
                .where(scripts: { id: ...last_script_id })
scripts = scripts.limit(limit) if limit

total_count = scripts.count
missing_fingerprint_count = scripts.left_joins(:code_similarity_fingerprint)
                                   .where(code_similarity_fingerprints: { script_id: nil })
                                   .count
puts "Starting below script ID #{last_script_id}; #{total_count} scripts in this run."
puts "#{missing_fingerprint_count} scripts need fingerprints."
puts "Checkpoint: #{checkpoint_path}"

processed_this_run = 0
scripts.find_each(order: :desc) do |script|
  if max_queue_size.positive?
    require 'sidekiq/api'
    loop do
      queue_size = Sidekiq::Queue.all.sum(&:size)
      break if queue_size < max_queue_size

      puts "Sidekiq queue depth is #{queue_size}; pausing for #{queue_poll_seconds} seconds."
      sleep(queue_poll_seconds)
    end
  end

  if !CodeSimilarityFingerprint.exists?(script_id: script.id) && script.current_code.present?
    fingerprint = TokenShingleSimilarityScorer.build_fingerprint(script.current_code)
    CodeSimilarityFingerprint.store_fingerprint!(script.id, fingerprint)
    fingerprint_count += 1
  end

  TokenShingleSimilarityJob.perform_later(script.id, only_higher_ids: true)

  last_script_id = script.id
  processed_count += 1
  processed_this_run += 1

  checkpoint = {
    order: 'descending',
    last_script_id:,
    processed_count:,
    fingerprint_count:,
  }
  temporary_checkpoint_path = "#{checkpoint_path}.tmp"
  File.write(temporary_checkpoint_path, JSON.pretty_generate(checkpoint))
  File.rename(temporary_checkpoint_path, checkpoint_path)

  puts "Enqueued jobs for #{processed_count} scripts through ID #{last_script_id}." if (processed_count % 100).zero?
  sleep(pause_seconds) if pause_seconds.positive?
end

puts "Backfill run complete: enqueued #{processed_this_run} jobs; #{processed_count} total enqueued."
puts "Fingerprints built during backfill: #{fingerprint_count}."
