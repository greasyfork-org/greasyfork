class AddUseNewDiscussionsToScript < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def up
    add_column :scripts, :use_new_discussions, :boolean, default: false, null: false
    Script.find_each do |s|
      s.update_column(:use_new_discussions, s.discussions.none?)
    end
    change_column_default :scripts, :use_new_discussions, true
  end
end
