class FillAdsenseApproved < ActiveRecord::Migration[5.2]
  def up
    execute 'update scripts set adsense_approved = true where ad_method = "ga"'
  end
end
