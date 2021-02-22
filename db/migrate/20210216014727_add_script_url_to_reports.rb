class AddScriptUrlToReports < ActiveRecord::Migration[6.1]
  def change
    add_column :reports, :script_url, :string
    add_column :reports, :reference_script_id, :integer
  end
end
