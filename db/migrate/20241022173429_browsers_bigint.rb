class BrowsersBigint < ActiveRecord::Migration[7.2]
  def change
    remove_foreign_key :compatibilities, :browsers
    change_column :compatibilities, :browser_id, :bigint
    change_column :browsers, :id, :bigint, auto_increment: true
    add_foreign_key :compatibilities, :browsers, on_delete: :cascade
  end
end
