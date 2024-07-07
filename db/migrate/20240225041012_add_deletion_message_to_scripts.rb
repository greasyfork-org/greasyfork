class AddDeletionMessageToScripts < ActiveRecord::Migration[7.1]
  def change
    add_column :scripts, :deletion_message, :text
  end
end
