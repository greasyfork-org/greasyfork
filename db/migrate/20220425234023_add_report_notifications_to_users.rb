class AddReportNotificationsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :notify_as_reporter, :boolean, default: true, null: false
    add_column :users, :notify_as_reported, :boolean, default: true, null: false
  end
end
