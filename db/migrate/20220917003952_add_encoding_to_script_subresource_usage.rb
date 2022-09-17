class AddEncodingToScriptSubresourceUsage < ActiveRecord::Migration[7.0]
  def change
    add_column :script_subresource_usages, :encoding, :string, limit: 10
    execute 'update script_subresource_usages set encoding = "hex" where encoding IS NULL and integrity_hash is not null'
  end
end
