require 'fileutils'
class ScriptObserver < ActiveRecord::Observer
  def after_save(script)
    cache_files = ["#{script.id}.meta.js", "#{script.id}.user.js"]
                  .map { |file_name| Rails.application.config.script_page_cache_directory.join(file_name) }
                  .select { |file_name| File.exist?(file_name) }
    File.delete(*cache_files)
    Dir.glob(Rails.application.config.script_page_cache_directory.join("scripts/#{script.id}-*")).each { |file| FileUtils.rm_rf(file) }
  end
end
