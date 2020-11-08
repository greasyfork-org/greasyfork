class BlockedScriptUrlPrefixDefaultFalse < ActiveRecord::Migration[6.0]
  def change
    change_column_default :blocked_script_urls, :prefix, false
    execute 'update blocked_script_urls set prefix = false'
  end
end
