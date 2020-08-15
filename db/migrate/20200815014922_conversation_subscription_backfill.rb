class ConversationSubscriptionBackfill < ActiveRecord::Migration[6.0]
  def up
    execute <<~SQL
      INSERT INTO conversation_subscriptions (conversation_id, user_id, created_at, updated_at)
      (SELECT conversation_id, user_id, NOW(), NOW() from conversations_users WHERE conversation_id IS NOT NULL AND user_id IS NOT NULL)
    SQL
  end
end
