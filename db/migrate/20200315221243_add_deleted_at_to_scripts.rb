class AddDeletedAtToScripts < ActiveRecord::Migration[6.0]
  def change
    add_column :scripts, :deleted_at, :datetime
  end
end
