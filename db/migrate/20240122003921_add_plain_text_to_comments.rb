class AddPlainTextToComments < ActiveRecord::Migration[7.1]
  def change
    add_column :comments, :plain_text, :text
  end
end
