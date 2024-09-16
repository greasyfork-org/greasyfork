class AddNotifyAdminToBlockedScriptCode < ActiveRecord::Migration[7.2]
  def change
    add_column :blocked_script_codes, :notify_admin, :boolean, default: true, null: false
  end
end
