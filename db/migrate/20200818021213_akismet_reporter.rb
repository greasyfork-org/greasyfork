class AkismetReporter < ActiveRecord::Migration[6.0]
  def change
    change_column_null :reports, :reporter_id, true
    add_column :reports, :auto_reporter, :string, limit: 10
  end
end
