class AddTitleToDiscussions < ActiveRecord::Migration[6.0]
  def change
    add_column :discussions, :title, :string
  end
end
