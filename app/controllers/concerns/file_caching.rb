# Writes content to a file for nginx to pick up on, compressing to gzip and brotli as well.
module FileCaching
  def file_cache_content(local_path, content, update_time: nil)
    unless File.exist?(local_path)
      FileUtils.mkdir_p(local_path.parent)
      File.write(local_path, content)
      File.utime(update_time.to_time, update_time.to_time, local_path) if update_time
    end

    unless File.exist?("#{local_path}.gz")
      system('gzip', '--keep', local_path.to_s)
      File.utime(update_time.to_time, update_time.to_time, "#{local_path}.gz") if update_time
    end

    return if File.exist?("#{local_path}.br")

    system('brotli', local_path.to_s)
    File.utime(update_time.to_time, update_time.to_time, "#{local_path}.br") if update_time
  end
end
