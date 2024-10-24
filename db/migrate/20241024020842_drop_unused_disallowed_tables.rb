class DropUnusedDisallowedTables < ActiveRecord::Migration[7.2]
  def change
    drop_table :disallowed_codes
    drop_table :disallowed_attributes
  end
end
