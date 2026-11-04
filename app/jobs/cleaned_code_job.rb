require 'js_cleanup'

class CleanedCodeJob < ApplicationJob
  queue_as :background

  def perform(script)
    unless script.js?
      self.class.delete_for_script(script)
      return
    end

    unclean_code = script.current_code

    begin
      clean_code = JsCleanup.cleanup(unclean_code)
    rescue JsCleanup::UncleanableException
      CleanedCode.where(script_id: script.id).delete_all
    else
      CleanedCode.upsert({ script_id: script.id, code: clean_code })
    end
  end

  def self.delete_for_script(script)
    CleanedCode.where(script_id: script.id).delete_all
  end
end
