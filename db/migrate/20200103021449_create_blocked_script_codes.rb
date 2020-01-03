class CreateBlockedScriptCodes < ActiveRecord::Migration[6.0]
  def change
    create_table :blocked_script_codes do |t|
      t.string :pattern, null: false
      t.string :public_reason, null: false
      t.string :private_reason, null: false
      t.boolean :serious, null: false, default: false
    end
  end
end
