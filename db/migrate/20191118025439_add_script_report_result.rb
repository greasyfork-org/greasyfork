class AddScriptReportResult < ActiveRecord::Migration[5.2]
  def change
    add_column :script_reports, :result, :string, limit: 10
    ScriptReport.where(resolved: true).each do |sr|
      if sr.script.nil?
        sr.result = 'upheld'
      elsif sr.script.locked
        sr.result = 'upheld'
      else
        sr.result = 'dismissed'
      end
      sr.save(validate: false)
    end
    remove_column :script_reports, :resolved
  end
end
