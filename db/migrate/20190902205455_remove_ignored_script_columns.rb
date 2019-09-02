class RemoveIgnoredScriptColumns < ActiveRecord::Migration[5.2]
  def change
    change_table :scripts do |t|
      t.remove :user_id
      t.remove :ad_method
    end
  end
end
