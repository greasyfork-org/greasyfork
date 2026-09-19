class DropDuplicateDiscussionScriptIndex < ActiveRecord::Migration[8.1]
  def change
    remove_index :discussions, name: "fk_rails_a52537835c"
  end
end
