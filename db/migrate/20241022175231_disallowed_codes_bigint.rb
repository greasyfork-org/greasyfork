class DisallowedCodesBigint < ActiveRecord::Migration[7.2]
  def change
    change_column :disallowed_codes, :id, :bigint, auto_increment: true
  end
end
