class AddCssConvertibleToScripts < ActiveRecord::Migration[5.2]
  def change
    add_column :scripts, :css_convertible_to_js, :boolean, default: false, null: false
  end
end
