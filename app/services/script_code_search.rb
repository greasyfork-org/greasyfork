require 'open3'

class ScriptCodeSearch
  BASE_PATH = Rails.root.join('tmp/gfcodesearch').to_s

  class << self
    def index(script_id)
      code = Script.find_by(id: script_id)&.current_code
      return unindex(script_id) unless code

      index_content(script_id, code)
    end

    def unindex(script_id)
      path = path_for(script_id)
      FileUtils.rm_f(path)
    end

    def index_all
      ensure_directory

      Rails.logger.info('Determining latest script version IDs')
      latest_script_version_ids = Script.connection.select_rows('SELECT MAX(id) FROM script_versions GROUP BY script_id')
      code_to_script = Script.connection.select_rows("SELECT rewritten_script_code_id, script_id FROM script_versions WHERE id IN (#{latest_script_version_ids.join(',')})").to_h

      Rails.logger.info('Writing files')
      code_to_script.keys.sort.in_groups_of(1000, false) do |batch|
        Script.connection.select_rows("SELECT id, code FROM script_codes WHERE id in (#{batch.join(',')})").each do |row|
          index_content(code_to_script[row[0]], row[1], skip_dir_create: true)
        end
      end

      Rails.logger.info('Removing stale files')
      (Set.new(Dir.children(BASE_PATH)) - code_to_script.values.to_set(&:to_s).map { |script_id| filename_for(script_id) }).each do |f|
        File.delete(File.join(BASE_PATH, f))
      end
    end

    def search(text, limit_to_ids: nil)
      content, _stderr, _status = if limit_to_ids.nil?
                                    Open3.capture3('grep', '-R', '-F', '-l', text, BASE_PATH)
                                  elsif limit_to_ids.none?
                                    ['', nil, nil]
                                  else
                                    Open3.capture3('grep', '-R', '-F', '-l', text, *limit_to_ids.map { |id| "#{BASE_PATH}/#{id}" })
                                  end
      content.split("\n").map { |line| line.delete_prefix("#{BASE_PATH}/") }.map(&:to_i)
    end

    private

    def index_content(script_id, code, skip_dir_create: false)
      ensure_directory unless skip_dir_create
      File.write(path_for(script_id), code)
    end

    def ensure_directory
      system('mkdir', '-p', BASE_PATH)
    end

    def path_for(script_id)
      File.join(BASE_PATH, filename_for(script_id))
    end

    def filename_for(script_id)
      script_id.to_s
    end
  end
end
