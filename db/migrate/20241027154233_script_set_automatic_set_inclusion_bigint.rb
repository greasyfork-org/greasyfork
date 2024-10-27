class ScriptSetAutomaticSetInclusionBigint < ActiveRecord::Migration[7.2]
  def change
    change_column :script_set_automatic_set_inclusions, :parent_id, :bigint
    execute 'delete t1 from script_set_automatic_set_inclusions t1 left join script_sets t2 on t1.parent_id = t2.id where t1.parent_id is not null and t2.id is null'
    add_foreign_key :script_set_automatic_set_inclusions, :script_sets, column: :parent_id, on_delete: :cascade

    change_column :script_set_automatic_set_inclusions, :script_set_automatic_type_id, :bigint
    add_foreign_key :script_set_automatic_set_inclusions, :script_set_automatic_types
  end
end
