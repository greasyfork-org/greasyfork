class CleanedCodeCleanupJob
  include Sidekiq::Job

  sidekiq_options queue: 'background'

  FILENAME_PATTERN = /\A([0-9]+)\.js\z/

  def perform
    valid_ids = Script.where(language: 'js').pluck(:id).to_set
    # check_for_missing doesn't work for clean because we're not guaranteed that CleanedCodeJob can actually write stuff for every file due to syntax issues.
    clean_path(valid_ids, CleanedCodeJob::BASE_CLEAN_PATH, check_for_missing: false)
    clean_path(valid_ids, CleanedCodeJob::BASE_DIRTY_PATH)
  end

  def clean_path(valid_ids, base_path, check_for_missing: true)
    return unless Dir.exist?(base_path)

    files = Dir.entries(base_path)
    files -= ['.', '..']

    id_filenames, other_files = files.partition { |f| FILENAME_PATTERN.match?(f) }
    files_to_delete = other_files

    files_to_delete += id_filenames.reject { |f| valid_ids.include?(f.split('.').first.to_i) }

    files_to_delete.each { |f| File.delete(File.join(base_path, f)) }

    return unless check_for_missing

    missing_file_ids = valid_ids - id_filenames.map { |filename| FILENAME_PATTERN.match(filename)[1].to_i }
    Script.where(id: missing_file_ids).find_each { |script| CleanedCodeJob.perform_later(script) }
  end
end
