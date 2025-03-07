class AddPrivateExplanationToReports < ActiveRecord::Migration[8.0]
  def change
    add_column :reports, :private_explanation, :text
  end
end
