class CreateBlockedScriptTexts < ActiveRecord::Migration[6.0]
  def change
    create_table :blocked_script_texts do |t|
      t.string :text, null: false
      t.string :public_reason, null: false
      t.string :private_reason, null: false
    end
  end
end
