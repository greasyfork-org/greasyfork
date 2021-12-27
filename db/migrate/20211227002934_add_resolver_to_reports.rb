class AddResolverToReports < ActiveRecord::Migration[6.1]
  def change
    add_column :reports, :resolver_id, :integer
  end
end
