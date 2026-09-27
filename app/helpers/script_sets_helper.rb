require 'timeout'

module ScriptSetsHelper
  def calculated_scripts_for_set(set)
    Timeout.timeout(10) { set.scripts(script_subset).to_a }
  rescue Timeout::Error
    nil
  end
end
