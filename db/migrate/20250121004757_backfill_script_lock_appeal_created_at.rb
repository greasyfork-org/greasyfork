class BackfillScriptLockAppealCreatedAt < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    ScriptLockAppeal.where(created_at: nil).find_each do |script_lock_appeal|
      last_report_date = ModeratorAction.where(report: Report.upheld.where(item_id: script_lock_appeal.script_id, item_type: 'Script')).maximum(:created_at)
      last_report_date = last_report_date ? (last_report_date + 1.second) : Time.zone.now
      script_lock_appeal.update!(created_at: last_report_date)
    end
  end
end
