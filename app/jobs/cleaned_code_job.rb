require 'js_cleanup'

class CleanedCodeJob < ApplicationJob
  queue_as :background

  BASE_CLEAN_PATH = Rails.root.join('tmp/cleanedcode').to_s
  BASE_DIRTY_PATH = Rails.root.join('tmp/dirtycode').to_s

  def perform(script)
    return unless script.js?

    unclean_code = script.current_code
    self.class.write_dirty_for_script(script, unclean_code)

    begin
      clean_code = JsCleanup.cleanup(unclean_code)
    rescue JsCleanup::UncleanableException
      CleanedCode.where(script_id: script.id).delete_all
      self.class.delete_for_script(script)
    else
      CleanedCode.upsert({ script_id: script.id, code: clean_code })
      self.class.write_clean_for_script(script, clean_code)
    end
  end

  def self.delete_for_script(script)
    delete_for_script_id(script.id)
  end

  def self.delete_for_script_id(id)
    FileUtils.rm_f(clean_path_for_script_id(id))
    FileUtils.rm_f(dirty_path_for_script_id(id))
  end

  def self.write_clean_for_script(script, code)
    ensure_clean_directory
    File.write(clean_path_for_script(script), code)
  end

  def self.write_dirty_for_script(script, code)
    ensure_dirty_directory
    File.write(dirty_path_for_script(script), code)
  end

  def self.clean_path_for_script(script)
    clean_path_for_script_id(script.id)
  end

  def self.clean_path_for_script_id(id)
    File.join(BASE_CLEAN_PATH, "#{id}.js")
  end

  def self.dirty_path_for_script(script)
    dirty_path_for_script_id(script.id)
  end

  def self.dirty_path_for_script_id(id)
    File.join(BASE_DIRTY_PATH, "#{id}.js")
  end

  def self.ensure_clean_directory
    system('mkdir', '-p', BASE_CLEAN_PATH)
  end

  def self.ensure_dirty_directory
    system('mkdir', '-p', BASE_DIRTY_PATH)
  end
end
