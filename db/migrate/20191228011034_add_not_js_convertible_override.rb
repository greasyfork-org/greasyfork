class AddNotJsConvertibleOverride < ActiveRecord::Migration[6.0]
  def change
    add_column :scripts, :not_js_convertible_override, :boolean, default: false, null: false
    add_column :script_versions, :not_js_convertible_override, :boolean, default: false, null: false
  end
end
