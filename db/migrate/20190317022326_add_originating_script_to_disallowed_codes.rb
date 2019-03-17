class AddOriginatingScriptToDisallowedCodes < ActiveRecord::Migration[5.2]
  def change
    add_column :disallowed_codes, :originating_script_id, :integer
  end
end
