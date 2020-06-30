class DropScriptUseNewDiscussions < ActiveRecord::Migration[6.0]
  def change
    remove_column :scripts, :use_new_discussions
  end
end
