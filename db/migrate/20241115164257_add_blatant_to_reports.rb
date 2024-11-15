class AddBlatantToReports < ActiveRecord::Migration[7.2]
  def change
    add_column :reports, :blatant, :boolean, default: false, null: false
  end
end
