class AddModeratorNoteToScriptReports < ActiveRecord::Migration[6.0]
  def change
    add_column :script_reports, :moderator_note, :text
  end
end
