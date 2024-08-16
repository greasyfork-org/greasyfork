class AddSummaryUrlToLicenses < ActiveRecord::Migration[7.1]
  def change
    add_column :licenses, :summary_url, :string
  end
end
