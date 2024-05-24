class AddModeratorReasonOverrideToReports < ActiveRecord::Migration[7.1]
  def change
    add_column :reports, :moderator_reason_override, :string, limit: 25
  end
end
