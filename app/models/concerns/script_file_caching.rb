module ScriptFileCaching
  extend ActiveSupport::Concern

  included do
    after_commit :clear_page_cache
  end

  def clear_page_cache
    cache_files = ["#{id}.meta.js", "#{id}.user.js"]
                  .map { |file_name| Rails.application.config.script_page_cache_directory.join(file_name) }
                  .select { |file_name| File.exist?(file_name) }
    File.delete(*cache_files)
    FileUtils.rm_rf(Rails.application.config.script_page_cache_directory.join("scripts/#{id}"))
    Dir.glob(Rails.application.config.script_page_cache_directory.join("scripts/#{id}-*")).each { |file| FileUtils.rm_rf(file) }
  end

  def clear_latest_cached_code
    %w[greasyfork sleazyfork].each do |site_name|
      Dir.glob(Rails.application.config.cached_code_path.join(site_name, 'latest', 'scripts', "#{id}.*")).each do |path|
        File.delete(path)
      rescue Errno::ENOENT
        # Already gone
      end
    end
  end
end
