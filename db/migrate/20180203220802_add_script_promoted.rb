class AddScriptPromoted < ActiveRecord::Migration[5.1]
  def change
		add_column :scripts, :promoted, :boolean, null: false, default: false, index: true
  end
end
