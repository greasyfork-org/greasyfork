class CleanedCodeLongtext < ActiveRecord::Migration[6.1]
  def change
    change_column :cleaned_codes, :code, :longtext
  end
end
