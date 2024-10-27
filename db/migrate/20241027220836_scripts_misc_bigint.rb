class ScriptsMiscBigint < ActiveRecord::Migration[7.2]
  def change
    change_table :scripts do |t|
      t.change :license_id, :bigint
      t.change :delete_report_id, :bigint
    end

    add_foreign_key :scripts, :licenses, if_not_exists: true

    execute "update scripts left join reports on delete_report_id = reports.id set delete_report_id = null where delete_report_id is not null and reports.id is null"
    add_foreign_key :scripts, :reports, column: :delete_report_id, if_not_exists: true
    remove_foreign_key :reports, :users, column: :reporter_id
    add_foreign_key :reports, :users, column: :reporter_id, on_delete: :nullify
  end
end
