class AddHashToScriptCodes < ActiveRecord::Migration[6.0]
  def change
    add_column :script_codes, :code_hash, :string, limit: 40 unless column_exists?(:script_codes, :code_hash)
  end
end
