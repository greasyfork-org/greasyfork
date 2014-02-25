class AddMarkupType < ActiveRecord::Migration
  def change
	add_column :users, :profile_markup, :string, :limit => 10, :default => 'html', :null => false
	add_column :scripts, :additional_info_markup, :string, :limit => 10, :default => 'html', :null => false
	add_column :script_versions, :additional_info_markup, :string, :limit => 10, :default => 'html', :null => false
  end
end
