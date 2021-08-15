class AddEditedAtToMessages < ActiveRecord::Migration[6.1]
  def change
    add_column :messages, :edited_at, :datetime
  end
end
