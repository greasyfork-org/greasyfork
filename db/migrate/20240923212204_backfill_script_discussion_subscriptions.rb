class BackfillScriptDiscussionSubscriptions < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    User.select(:id).where(author_email_notification_type_id: 3).find_each do |user|
      discussion_ids = Discussion.joins(script: :authors).where(authors: { user_id: user.id}).pluck('discussions.id')
      next if discussion_ids.empty?

      DiscussionSubscription.upsert_all(
        discussion_ids.map{|discussion_id| { discussion_id:, user_id: user.id}},
        update_only: [])
    end
  end
end
