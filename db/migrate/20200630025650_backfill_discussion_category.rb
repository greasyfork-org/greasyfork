class BackfillDiscussionCategory < ActiveRecord::Migration[6.0]
  def up
    script_discussion_category_id = Discussion.connection.select_value('select id from discussion_categories where category_key = "script-discussions"')
    execute "UPDATE discussions SET discussion_category_id = #{script_discussion_category_id}"
  end
end
