class DropSyntaxHighlightedCodes < ActiveRecord::Migration[8.1]
  def up
    drop_table :syntax_highlighted_codes
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
