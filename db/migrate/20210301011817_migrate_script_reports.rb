class MigrateScriptReports < ActiveRecord::Migration[6.1]
  def up
    execute <<~SQL
      INSERT INTO reports (item_type, item_id, reason, explanation, explanation_markup, reporter_id, result, auto_reporter, reference_script_id, rebuttal, rebuttal_by_user_id, moderator_notes, created_at, updated_at)
      (SELECT 'Script', script_id, report_type, CONCAT('Migrated from script report ', script_reports.id, '\n\n', `details`, '\n\n', `additional_info`), 'text', reporter_id, IF(scripts.locked AND result IS NULL, 'upheld', result), auto_reporter, reference_script_id, rebuttal, null, moderator_note, script_reports.created_at, script_reports.created_at FROM script_reports LEFT JOIN scripts on scripts.id = script_id where reporter_id is not null or auto_reporter is not null)
    SQL
  end
end
