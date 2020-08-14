class AddAkismetResultsToDiscussions < ActiveRecord::Migration[6.0]
  def change
    add_column :discussions, :akismet_spam, :boolean
    add_column :discussions, :akismet_blatant, :boolean
  end
end
