class AddBlockTypeToSpammyEmailDomain < ActiveRecord::Migration[6.0]
  def up
    add_column :spammy_email_domains, :block_type, :string, limit: 20
    execute 'update spammy_email_domains SET block_type = "confirmation" WHERE complete_block = FALSE'
    execute 'update spammy_email_domains SET block_type = "block_script" WHERE complete_block = TRUE'
    change_column_null :spammy_email_domains, :block_type, false
    remove_column :spammy_email_domains, :complete_block
  end
end
