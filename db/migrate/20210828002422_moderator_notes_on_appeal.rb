class ModeratorNotesOnAppeal < ActiveRecord::Migration[6.1]
  def change
    add_column :script_lock_appeals, :moderator_notes, :text
  end
end
