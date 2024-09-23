class SubscribeOnScriptDiscussionBackfill < ActiveRecord::Migration[7.2]
  def change
    execute <<~SQL
      UPDATE users SET subscribe_on_script_discussion = false WHERE author_email_notification_type_id = 1
    SQL
  end
end
