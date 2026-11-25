class DeleteOrphanedConversations < ActiveRecord::Migration[8.1]
  def up
    # Conversations are created with two participants; account deletion previously removed only the join row.
    Conversation.where(<<~SQL.squish).find_each(&:destroy!)
      NOT EXISTS (SELECT 1 FROM users WHERE users.id = conversations.starting_user_id)
      OR EXISTS (
        SELECT 1 FROM conversations_users
        LEFT JOIN users ON users.id = conversations_users.user_id
        WHERE conversations_users.conversation_id = conversations.id AND users.id IS NULL
      )
      OR EXISTS (
        SELECT 1 FROM messages
        LEFT JOIN users ON users.id = messages.poster_id
        WHERE messages.conversation_id = conversations.id AND users.id IS NULL
      )
      OR (
        SELECT COUNT(DISTINCT conversations_users.user_id)
        FROM conversations_users
        INNER JOIN users ON users.id = conversations_users.user_id
        WHERE conversations_users.conversation_id = conversations.id
      ) < 2
    SQL
  end
end
