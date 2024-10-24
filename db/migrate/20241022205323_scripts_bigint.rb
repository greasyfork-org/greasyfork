class ScriptsBigint < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    # For things that use script_id and a FK with on_delete: cascade
    tables_with_script_id = [:antifeatures, :authors, :cleaned_codes, :compatibilities, :daily_install_counts, :daily_update_check_counts, :discussions, :install_counts, :localized_script_attributes, :script_applies_tos, :script_invitations, :script_lock_appeals, :script_similarities, :script_subresource_usages, :script_versions, :syntax_highlighted_codes, :update_check_counts]
    tables_with_script_id = tables_with_script_id.reject{|table_name|  bigint?(table_name, :script_id) }

    tables_with_script_id.each do |table_name|
      remove_foreign_key table_name, :scripts, column: :script_id, if_exists: true
      change_column table_name, :script_id, :bigint
    end

    # FKs with different names
    remove_foreign_key :script_similarities, :scripts, column: :other_script_id, if_exists: true unless bigint?(:script_similarities, :other_script_id)
    change_column :script_similarities, :other_script_id, :bigint
    remove_foreign_key :blocked_script_codes, :scripts, column: :originating_script_id, if_exists: true unless bigint?(:blocked_script_codes, :originating_script_id)
    change_column :blocked_script_codes, :originating_script_id, :bigint

    # FKs with without cascade delete
    change_column :scripts, :replaced_by_script_id, :bigint
    remove_foreign_key :scripts, :scripts, column: :promoted_script_id, if_exists: true unless bigint?(:scripts, :promoted_script_id)
    change_column :scripts, :promoted_script_id, :bigint

    # These don't get FKs
    change_column :moderator_actions, :script_id, :bigint
    change_column :reports, :reference_script_id, :bigint

    change_column :scripts, :id, :bigint

    execute 'delete install_counts from install_counts left join scripts on scripts.id = script_id where scripts.id is null'
    execute 'delete syntax_highlighted_codes from syntax_highlighted_codes left join scripts on scripts.id = script_id where scripts.id is null'
    execute 'delete update_check_counts from update_check_counts left join scripts on scripts.id = script_id where scripts.id is null'
    execute 'update scripts s1 left join scripts s2 on s1.replaced_by_script_id = s2.id set s1.replaced_by_script_id = null where s1.replaced_by_script_id is not null and s2.id is null'

    tables_with_script_id.each do |table_name|
      add_foreign_key table_name, :scripts, on_delete: :cascade, if_not_exists: true
    end

    add_foreign_key :script_similarities, :scripts, column: :other_script_id, on_delete: :cascade, if_not_exists: true unless Rails.env.production?
    add_foreign_key :scripts, :scripts, column: :replaced_by_script_id, on_delete: :nullify, if_not_exists: true
    add_foreign_key :scripts, :scripts, column: :promoted_script_id, on_delete: :nullify, if_not_exists: true
    add_foreign_key :blocked_script_codes, :scripts, column: :originating_script_id, on_delete: :nullify, if_not_exists: true
  end

  def bigint?(table, col)
    Script.connection.columns(table.to_sym).find{|c| c.name == col.to_s}.sql_type == 'bigint(20)'
  end
end
