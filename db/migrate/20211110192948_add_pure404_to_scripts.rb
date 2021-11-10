class AddPure404ToScripts < ActiveRecord::Migration[6.1]
  def change
    add_column :scripts, :pure_404, :boolean, null: false, default: false
  end
end
