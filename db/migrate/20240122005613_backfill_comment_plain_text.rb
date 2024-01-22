class BackfillCommentPlainText < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    Comment.where(plain_text: nil).find_each{|c| c.set_plain_text; c.update_column(:plain_text, c.plain_text) }
  end
end
