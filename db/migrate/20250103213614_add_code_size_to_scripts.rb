class AddCodeSizeToScripts < ActiveRecord::Migration[8.0]
  def change
    add_column :scripts, :code_size, :integer, default: 0, null: false
  end
end
