class RemoveUnusedLocalizedScriptAttribute < ActiveRecord::Migration[6.1]
  def change
    remove_column(:localized_script_attributes, :sync_source_id)
  end
end
