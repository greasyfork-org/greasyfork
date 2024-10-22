class DropScreenshots < ActiveRecord::Migration[7.2]
  def change
    drop_table :screenshots_script_versions
    drop_table :screenshots
  end
end
