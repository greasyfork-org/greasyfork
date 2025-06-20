require 'js_cleanup'

class CleanedCodeJob < ApplicationJob
  queue_as :background

  BASE_PATH = Rails.root.join('tmp/cleanedcode').to_s

  def perform(script)
    return unless script.js?

    clean_code = JsCleanup.cleanup(script.current_code)
  rescue JsCleanup::UncleanableException
    CleanedCode.where(script_id: script.id).delete_all
    self.class.delete_for_script(script)
  else
    CleanedCode.upsert({ script_id: script.id, code: clean_code })
    self.class.write_for_script(script, clean_code)
  end

  def self.delete_for_script(script)
    delete_for_script_id(script.id)
  end

  def self.delete_for_script_id(id)
    path = path_for_script_id(id)
    FileUtils.rm_f(path)
  end

  def self.write_for_script(script, code)
    ensure_directory
    path = path_for_script(script)
    File.write(path, code)
  end

  def self.path_for_script(script)
    path_for_script_id(script.id)
  end

  def self.path_for_script_id(id)
    File.join(BASE_PATH, "#{id}.js")
  end

  def self.ensure_directory
    system('mkdir', '-p', BASE_PATH)
  end
end
