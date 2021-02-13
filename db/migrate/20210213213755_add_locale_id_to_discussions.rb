class AddLocaleIdToDiscussions < ActiveRecord::Migration[6.1]
  def change
    add_column :discussions, :locale_id, :integer
  end
end
