class CleanedCodeCleanupJob
  include Sidekiq::Job

  sidekiq_options queue: 'background'

  FILENAME_PATTERN = /\A([0-9]+)\.js\z/

  def perform
    files = Dir.entries(CleanedCodeJob::BASE_PATH)
    files -= ['.', '..']

    id_filenames, other_files = files.partition { |f| FILENAME_PATTERN.match?(f) }
    files_to_delete = other_files

    valid_ids = Script.where(language: 'js').pluck(:id).to_set
    files_to_delete += id_filenames.reject { |f| valid_ids.include?(f.split('.').first.to_i) }

    files_to_delete.each { |f| File.delete(File.join(CleanedCodeJob::BASE_PATH, f)) }

    # This doesn't work because we're not guaranteed that CleanedCodeJob can actually write stuff for every file due to syntax issues.
    # missing_file_ids = valid_ids - id_filenames.map{|filename| FILENAME_PATTERN.match(filename)[1].to_i }
    # Script.find(missing_file_ids).each {|script| CleanedCodeJob.perform_later(script) }
  end
end
