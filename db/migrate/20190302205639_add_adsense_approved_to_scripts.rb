class AddAdsenseApprovedToScripts < ActiveRecord::Migration[5.2]
  def change
    add_column :scripts, :adsense_approved, :boolean
  end
end
