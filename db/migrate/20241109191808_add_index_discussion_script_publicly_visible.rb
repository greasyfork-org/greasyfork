class AddIndexDiscussionScriptPubliclyVisible < ActiveRecord::Migration[7.2]
  def change
    add_index :discussions, [:script_id, :publicly_visible]
  end
end
