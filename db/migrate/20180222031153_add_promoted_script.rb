class AddPromotedScript < ActiveRecord::Migration[5.1]
  def change
    add_column :scripts, :promoted_script_id, :int
    add_foreign_key :scripts, :scripts, column: :promoted_script_id, on_delete: :nullify
  end
end
