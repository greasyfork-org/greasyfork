class ScriptSetScriptInclusionBigint < ActiveRecord::Migration[7.2]
  def change
    change_table :script_set_script_inclusions do |t|
      t.change :parent_id, :bigint
      t.change :child_id, :bigint
    end

    execute 'delete t1 from script_set_script_inclusions t1 left join script_sets t2 on t1.parent_id = t2.id where t1.parent_id is not null and t2.id is null'
    add_foreign_key :script_set_script_inclusions, :script_sets, column: :parent_id, on_delete: :cascade

    execute 'delete t1 from script_set_script_inclusions t1 left join scripts t2 on t1.child_id = t2.id where t1.child_id is not null and t2.id is null'
    add_foreign_key :script_set_script_inclusions, :scripts, column: :child_id, on_delete: :cascade
  end
end
