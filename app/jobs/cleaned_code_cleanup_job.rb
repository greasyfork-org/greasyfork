class CleanedCodeCleanupJob
  include Sidekiq::Job

  sidekiq_options queue: 'background'

  def perform
    files = Dir.entries(CleanedCodeJob::BASE_PATH)
    files -= ['.', '..']

    id_filenames, other_files = files.partition { |f| /\A[0-9]+\.js/.match?(f) }
    files_to_delete = other_files

    valid_ids = Script.where(language: 'js').pluck(:id).to_set
    files_to_delete += id_filenames.reject { |f| valid_ids.include?(f.split('.').first.to_i) }

    files_to_delete.each { |f| File.delete(File.join(CleanedCodeJob::BASE_PATH, f)) }
  end
end
