class AddAnnouncementsSeenToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :announcements_seen, :string
  end
end
