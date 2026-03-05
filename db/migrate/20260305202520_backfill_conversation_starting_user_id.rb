class BackfillConversationStartingUserId < ActiveRecord::Migration[8.1]
  def change
    Conversation.find_each do |conversation|
      conversation.update_column(:starting_user_id, conversation.messages.first.poster_id)
    end
  end
end
