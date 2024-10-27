class AddFkScriptSubresourceUsages < ActiveRecord::Migration[7.2]
  def change
    add_foreign_key :script_subresource_usages, :scripts, on_delete: :cascade
    add_foreign_key :script_subresource_usages, :subresources, on_delete: :cascade
  end
end
