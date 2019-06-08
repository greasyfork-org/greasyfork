class AddSlowBanToDisallowedCodes < ActiveRecord::Migration[5.2]
  def change
    add_column :disallowed_codes, :slow_ban, :boolean, default: false, null: false
  end
end
