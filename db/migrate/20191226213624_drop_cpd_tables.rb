class DropCpdTables < ActiveRecord::Migration[5.2]
  def change
    drop_table :cpd_duplications
    drop_table :cpd_duplication_scripts
  end
end
