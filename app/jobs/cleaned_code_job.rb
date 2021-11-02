require 'js_cleanup'

class CleanedCodeJob < ApplicationJob
  queue_as :background

  def perform(script)
    CleanedCode.upsert({ script_id: script.id, code: JsCleanup.cleanup(script.current_code) })
  end
end
