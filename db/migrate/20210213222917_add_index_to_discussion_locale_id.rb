class AddIndexToDiscussionLocaleId < ActiveRecord::Migration[6.1]
  def change
    add_index :discussions, :locale_id
  end
end
