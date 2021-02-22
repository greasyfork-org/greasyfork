class ChangeReportReasonLength < ActiveRecord::Migration[6.1]
  def change
    change_column :reports, :reason, :string, limit: 25, null: false
  end
end
