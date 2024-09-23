class AddSubscribeOnScriptDiscussionToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :subscribe_on_script_discussion, :boolean, default: true, null: false
  end
end
