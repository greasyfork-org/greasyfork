class DropscriptAppliesTosBak < ActiveRecord::Migration[7.1]
  def change
    drop_table :script_applies_tos_bak, if_exists: true
  end
end
