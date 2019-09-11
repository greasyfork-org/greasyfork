class AddHasSyntaxErrorToScripts < ActiveRecord::Migration[5.2]
  def change
    add_column :scripts, :has_syntax_error, :boolean, default: false, null: false
  end
end
