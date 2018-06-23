class CreateScriptReports < ActiveRecord::Migration[5.2]
  def change
    create_table :script_reports do |t|
      t.datetime :created_at, null: false
      t.belongs_to :script, index: true, null: false
      t.belongs_to :reference_script, index: true, null: false
      t.text :copy_details, null: false
      t.text :additional_info, null: false
      t.text :rebuttal
      t.boolean :resolved, null: false, default: false
    end
  end
end
