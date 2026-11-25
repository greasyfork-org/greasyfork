class LegacyComments < ActiveRecord::Migration[8.1]
  def up
    change_table :GDN_Comment, bulk: true do |t|
      t.remove_index name: 'TX_Comment'
      t.remove_index name: 'IX_Comment_DateInserted'
      t.remove_index name: 'IX_Comment_1'
      t.remove_index name: 'FK_Comment_InsertUserID'
      t.remove_index name: 'IX_Comment_Score'

      t.remove :InsertUserID, :UpdateUserID, :DeleteUserID, :Body, :Format, :DateInserted, :DateDeleted, :DateUpdated, :InsertIPAddress, :UpdateIPAddress, :Flag, :Score, :Attributes
    end

    rename_table :GDN_Comment, :legacy_comments
    change_table :legacy_comments, bulk: true do |t|
      t.rename :CommentID, :id # rubocop:disable Rails/DangerousColumnNames
      t.rename :DiscussionID, :discussion_id
    end
    execute 'ALTER TABLE legacy_comments ENGINE=InnoDB'
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
