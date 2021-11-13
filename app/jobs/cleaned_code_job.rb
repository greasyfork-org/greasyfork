require 'js_cleanup'

class CleanedCodeJob < ApplicationJob
  queue_as :background

  def perform(script)
    return unless script.js?

    clean_code = JsCleanup.cleanup(script.current_code)
  rescue JsCleanup::UncleanableException
    CleanedCode.where(script_id: script.id).delete_all
  else
    CleanedCode.upsert({ script_id: script.id, code: clean_code })
  end
end
