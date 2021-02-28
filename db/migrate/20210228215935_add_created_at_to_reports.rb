class AddCreatedAtToReports < ActiveRecord::Migration[6.1]
  def change
    add_timestamps(:reports)
    execute 'UPDATE reports SET created_at = NOW() where created_at IS NULL'
    execute 'UPDATE reports SET updated_at = NOW() where updated_at IS NULL'
  end
end
