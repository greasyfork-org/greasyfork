class AddRebuttalToReports < ActiveRecord::Migration[6.1]
  def change
    add_column :reports, :rebuttal, :text
    add_column :reports, :rebuttal_by_user_id, :integer
  end
end
