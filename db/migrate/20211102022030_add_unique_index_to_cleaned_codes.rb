class AddUniqueIndexToCleanedCodes < ActiveRecord::Migration[6.1]
  def change
    add_index :cleaned_codes, :script_id, unique: true
  end
end
