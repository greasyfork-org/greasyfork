class DropIgnoredNotifyColumns < ActiveRecord::Migration[7.2]
  def change
    remove_columns :users, :notify_as_reporter, :notify_as_reported
  end
end
