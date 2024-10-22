class SyntaxHighlightedCodesBigint < ActiveRecord::Migration[7.2]
  def change
    change_column :syntax_highlighted_codes, :id, :bigint, auto_increment: true
  end
end
