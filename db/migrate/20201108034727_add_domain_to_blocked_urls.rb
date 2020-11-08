class AddDomainToBlockedUrls < ActiveRecord::Migration[6.0]
  def change
    add_column :blocked_script_urls, :prefix, :boolean, null: false, default: true
  end
end
