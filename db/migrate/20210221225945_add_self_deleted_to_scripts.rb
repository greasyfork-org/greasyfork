class AddSelfDeletedToScripts < ActiveRecord::Migration[6.1]
  def change
    add_column :scripts, :self_deleted, :boolean, null: false, default: false
  end
end
