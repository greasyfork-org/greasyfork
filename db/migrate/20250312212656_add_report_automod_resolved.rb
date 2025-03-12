class AddReportAutomodResolved < ActiveRecord::Migration[8.0]
  def change
    add_column :reports, :automod_resolved, :boolean, default: false, null: false
  end
end
