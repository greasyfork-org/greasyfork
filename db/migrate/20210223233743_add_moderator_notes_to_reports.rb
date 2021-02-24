class AddModeratorNotesToReports < ActiveRecord::Migration[6.1]
  def change
    add_column :reports, :moderator_notes, :text
  end
end
