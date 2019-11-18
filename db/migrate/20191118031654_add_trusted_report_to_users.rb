class AddTrustedReportToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :trusted_reports, :boolean, null: false, default: false
  end
end
