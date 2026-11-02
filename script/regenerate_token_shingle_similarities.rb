require 'json'
require 'sidekiq/api'

# Enqueues a TokenShingleSimilarityJob for every script that has (or previously had) similarity data.
# Fingerprints must already be generated. Each job uses only_higher_ids so that every pair is computed once,
# from its lower-ID script, and replaces all rows where that script is the lower ID.

checkpoint_path = Rails.root.join(ENV.fetch('CHECKPOINT_PATH', 'tmp/token_shingle_similarity_regeneration.json'))
pause_seconds = Float(ENV.fetch('PAUSE_SECONDS', '0'))
max_queue_size = Integer(ENV.fetch('MAX_SIDEKIQ_QUEUE_SIZE', '100'), 10)
queue_poll_seconds = Float(ENV.fetch('QUEUE_POLL_SECONDS', '30'))
queue_name = TokenShingleSimilarityJob.new.queue_name
limit = ENV['LIMIT']&.then { |value| Integer(value, 10) }

raise 'PAUSE_SECONDS must not be negative' if pause_seconds.negative?
raise 'MAX_SIDEKIQ_QUEUE_SIZE must be positive' unless max_queue_size.positive?
raise 'QUEUE_POLL_SECONDS must be positive' unless queue_poll_seconds.positive?
raise 'LIMIT must be positive' if limit && !limit.positive?

if File.exist?(checkpoint_path)
  checkpoint = JSON.parse(File.read(checkpoint_path))
  raise 'Checkpoint was created for a different regeneration order' unless checkpoint['order'] == 'ascending'

  last_script_id = Integer(checkpoint.fetch('last_script_id'))
  processed_count = Integer(checkpoint.fetch('processed_count'))
else
  last_script_id = 0
  processed_count = 0
end

# Scripts without a fingerprint are included only if they have stale similarity rows, which their job will delete.
scripts = Script.where('scripts.id > ?', last_script_id)
                .where(
                  'scripts.id IN (SELECT script_id FROM code_similarity_fingerprints) ' \
                  'OR scripts.id IN (SELECT DISTINCT script_id FROM token_shingle_similarities)'
                )
scripts = scripts.limit(limit) if limit

puts "Resuming after script ID #{last_script_id}; #{scripts.count} scripts in this run (#{processed_count} already enqueued)."
puts "Checkpoint: #{checkpoint_path}"
puts "Pausing while the Sidekiq #{queue_name} queue has #{max_queue_size} or more jobs."

processed_this_run = 0
scripts.pluck(:id).sort.each do |script_id|
  loop do
    queue_size = Sidekiq::Queue.new(queue_name).size
    break if queue_size < max_queue_size

    puts "Sidekiq #{queue_name} queue depth is #{queue_size}; pausing for #{queue_poll_seconds} seconds."
    sleep(queue_poll_seconds)
  end

  TokenShingleSimilarityJob.perform_later(script_id, only_higher_ids: true)

  last_script_id = script_id
  processed_count += 1
  processed_this_run += 1

  # The checkpoint is written after enqueueing, so a crash can re-enqueue one script; the job is idempotent.
  temporary_checkpoint_path = "#{checkpoint_path}.tmp"
  File.write(temporary_checkpoint_path, JSON.pretty_generate(order: 'ascending', last_script_id:, processed_count:))
  File.rename(temporary_checkpoint_path, checkpoint_path)

  puts "Enqueued jobs for #{processed_count} scripts through ID #{last_script_id}." if (processed_count % 100).zero?
  sleep(pause_seconds) if pause_seconds.positive?
end

puts "Regeneration run complete: enqueued #{processed_this_run} jobs; #{processed_count} total enqueued."
