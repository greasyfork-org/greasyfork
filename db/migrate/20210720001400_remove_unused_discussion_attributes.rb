class RemoveUnusedDiscussionAttributes < ActiveRecord::Migration[6.1]
  def change
    remove_columns(:discussions, :akismet_spam, :akismet_blatant)
  end
end
