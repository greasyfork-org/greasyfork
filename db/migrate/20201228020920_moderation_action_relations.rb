class ModerationActionRelations < ActiveRecord::Migration[6.1]
  def change
    change_column_null :moderator_actions, :reason, true
    add_column :moderator_actions, :report_id, :bigint
    add_column :moderator_actions, :script_report_id, :bigint
    add_foreign_key :moderator_actions, :reports, on_delete: :nullify
    add_foreign_key :moderator_actions, :script_reports, on_delete: :nullify
  end
end
