class DropUiAvailable < ActiveRecord::Migration[8.1]
  def change
    remove_column :locales, :ui_available
  end
end
