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
      File.delete(path) if File.exist?(path)
    end

    def index_all
      script_and_sv_ids = Script.connection.select_rows('SELECT script_id, MAX(id) FROM script_versions GROUP BY script_id')
      script_ids = script_and_sv_ids.map(&:first)
      script_version_ids = script_and_sv_ids.map(&:last)
      script_version_ids.in_groups_of(1000, false) do |batch|
        Script.connection.select_rows("SELECT script_id, code FROM script_versions JOIN script_codes ON rewritten_script_code_id = script_codes.id WHERE script_versions.id in (#{batch.join(',')})").each do |row|
          index_content(row[0], row[1], skip_dir_create: true)
        end
      end
      (Set.new(Dir.children(BASE_PATH)) - script_ids.map(&:to_s).to_set).each do |f|
        File.delete(File.join(BASE_PATH, f))
      end
    end

    def search(text)
      content, _stderr, _status = Open3.capture3('grep', '-R', '-F', '-l', text, BASE_PATH)
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
      system('mkdir', '-p', BASE_PATH)
      File.join(BASE_PATH, script_id.to_s)
    end
  end
end
